title: Understanding Legacy Code Using Explorative Test-Driven Development Technique.

Today we are going to learn how to eliminate the fear of changing legacy code. We will learn how to confidently and in small iterations understand the legacy code better while increasing the test coverage in the process. While code examples are in Ruby programming language, the technique applied is language-agnostic.

For this article, we will need to define what Legacy Code means.

## Legacy Code

Legacy code is challenging to understand when reading. Such code has no or close to no tests. Also, any legacy code brings the value to the business and customers.

Let's give an outline of what we will be going through today:

- We will define "Knowledge" and "Mutation" concepts in the context of the production code.
- We will take a look into the relation between the production system and its test suite. While the connection from test suite to the production system is simple, the reverse connection is subtle and have some unusual and unexpected properties.
- We will dismantle different test coverage metrics and outline the most valuable and useful one.
- We will explore existing technique called Mutational Testing, that is simple to apply to the untested code to increase its test coverage.
- We will introduce the technique called Explorative Test-Driven Development, that is an improvement of Mutational Testing method, which allows us to increase understanding of the legacy code in small steps - confidently and incrementally.
- We will look at the example legacy code and apply Explorative TDD to it.
- We will see the opportunities to use Explorative TDD technique outside the context of the Legacy Code.

Shall we get the ball rolling?

## Knowledge in Production Code

"Knowledge in Production Code" is any small bit of functionality that represents any part of the business rule or underlying infrastructure rule. Example bits of knowledge in production code:

- a variable assignment (or binding): `a_variable = ...`,
- the presence of the `if` statement: `if ... end`,
- an `if` condition: `if has_certain_property()`,
- an `if` body: `if ...  do_something_interesting  end`,
- the presence of the `else` clause: `if ... else ... end`,
- an `else` body: `if ... else  do_something_different  end`,
- function (or method) call: `a_function(arguments)`, `receiver.a_method(arguments)`,
- every argument of the function (or method) call (including receiver),
- a constant: `42`,
- the fact that function (or method) returns early: `if ...  return 42  end`,
- what the function (or method) returns,
- the presence of the iteration: `...each do |x| ... end`,
- what we iterate through: `list.each do ...`,
- and how we are iterating: `...each do |x|  do_something_with(x)  end`,
- and so on.

I think the idea "Knowledge in Production Code" should be more or less clear. More interesting is what we can do with knowledge in our system: we can re-organize knowledge differently keeping all the behaviors of the system - this is called Refactoring, or we can do the opposite: we can change bits of knowledge without changing structure of the system - one such change operation is called Mutation:

## Mutation

Mutation - granular change of the knowledge in the system that changes behavior of the system. Let's take a look at the simple example:

```ruby
if cell_is_alive
  do_this
else
  do_some_other_thing
end
```

This code is maybe a part of some sort of cell organism simulation (like Game Of Life or similar). Let's see which different mutations can be applied here:

- change the `if` condition to always be `true`: `if true ...`,
- change the `if` condition to always be `false`: `if false ...`,
- invert the `if` condition: `if !cell_is_alive`,
- commenting out the `if` body: `# do_this`,
- commenting out the `else` body: `# do_some_other_thing`.

With that done, let's take a look into how production code and its test suite relate to each other.

## Code and Test Suite Relationship

So, how does the test suite affect production code? First, it makes sure the production code is correct. Also, good test suite enables quick and ruthless refactoring by eliminating (or minimizing) the risks of breaking it. Essentially, good test suite gives us the power and courage to introduce changes. Also, test code is always coupled to the production code it is testing in one way or another.

Okay, how does the production code affect its test suite? As test code is coupled to the production code it tests, the changes in production code may cause ripple effects on its test suite. Practically speaking, a mutation should always lead to a test failure if the test suite is good enough because every tiny bit of knowledge in the production code (except, maybe, some configuration) should be verified by its test suite.

Interestingly enough, such knowledge change is an act of assertion about the presence of the test: if the knowledge is covered by test suite well, then there should be a test failure, whenever mutation is introduced to this bit of knowledge; if, after mutation was introduced, there is no test failure, this is a failed assertion about test presence or correctness. So one might say:

> Knowledge Change is a Test for the Test

This is very interesting idea since it implies production code can be used as a test suite for its own test suite, which may enable TDD-like iterative development of the test suite that does not exists.

So far, we have covered the idea of knowledge in the production code, explored ways this knowledge can be changed in a way that changes the behavior - we call it a mutation; and also we explored the mirror-like relation between production code and its test suite. We have still a lot of ground to cover, let's dive in:

## Most Useful Coverage Metric

There is a few well-known test coverage metrics that are being used quite often by software engineering teams, such as:

- line coverage, and
- branch coverage.

There is another one, called path coverage - it is about coverage of all possible code paths in the code, which quickly becomes impractical as the application size grows because of exponential growth of the amount of these different paths.

Line coverage and branch coverage (also, path coverage) all share one major problem - covered line/branch/path doesn't mean it was actually verified - it means that it was only executed. Great example: remove all the assertions from your tests and the coverage metric will stay the same.

So, what if we could introduce all possible and sane mutations to our code and count how much of them cause test failure? - we will get the knowledge coverage metric. Other name for it is Test Semantic Stability and it can range from 0% to 100%. Even 100% line/path coverage can easily yield 0% Test Semantic Stability. This metric actually proves that code is, indeed well-tested and verified (although, it doesn't say anything about tests' design and cleanliness): make one assertion incorrect, or not precise enough and the metric will go down by a few mutations.

This is why Test Semantic Stability is the most useful coverage metric.

So, How do we check if some bit of knowledge in my system is covered by the test(s)? We break it! - introduce a very small granular breaking change to that bit of knowledge. The test suite should fail. If it doesn't - knowledge is not covered well enough. And that leads us to the technique that allows us to keep Semantic Test Stability up high:

## Mutational Testing

1. Narrow scope to single granular piece of knowledge.
2. Break this knowledge (introduce simple granular breaking change - mutation).
3. Make sure there is a test suite failure.
4. Restore the knowledge to its original state (CTRL+Z, ideally).

Let's see it in action:

```ruby
if cell_is_alive
  do_this
else
  do_some_other_thing
end
```

First, we need to narrow our scope to a single bit of knowledge. For example, the `if` condition: `if cell_is_alive`. Then we need to introduce the mutation `if true` and we need to make sure that there is a test failure. Let's run the test suite:

```
$ rake test
....

Finished in 0.02343 seconds (files took 0.11584 seconds to load)
4 examples, 0 failures
```

Oh no! It didn't fail anywhere! That means that we have a "failing test" for our test suite. In this case we need to add the test for the negative case:

```ruby
cell_is_alive = false
expect(did_some_other_thing).to eq(true)
```

And when we run the test suite:

```
$ rake test
....F

Finished in 0.02343 seconds (files took 0.11584 seconds to load)
5 examples, 1 failure
```

It fails! Great - that means that our test for the test suite is passing now. As a last step of this mutational testing iteration we have to return the code to its original state:

```ruby
if cell_is_alive
  do_this
else
  do_some_other_thing
end
```

After doing this, our tests should pass!:

```
$ rake test
.....

Finished in 0.02343 seconds (files took 0.11584 seconds to load)
5 examples, 0 failures
```

And they do. This concludes one iteration of the mutational testing. Usually, to accomplish any useful behavior we would like to combine many bits of knowledge. If we want to better understand how the system works, we need to focus on groups of bits of knowledge. This is what Explorative TDD technique is about:

## Explorative Test-Driven Development

The technique used to increase our understanding of the Legacy Code, while increasing its Test Semantic Stability (the most useful coverage metric). The technique roughly looks like that:

1. Narrow scope to some manageable knowledge and isolate it (manageable knowledge = method/function/class/module).
2. Read, try to understand, pick granular piece of knowledge, and make an assumption to which behavior it contributes and how.
3. Write a test to verify this assumption.
4. Make sure test passes (by altering the assumption, or fixing production code (bugs)). PS: be careful with bugs, since they might be weird behaviors that are actually bringing someone tremendous value. When finding one of these, consult with stakeholders if that is a bug or a feature.
5. Apply Mutational Testing to each related granular piece of knowledge to verify that the understanding (and the test) is correct (this may introduce more tests).
6. Go back to 2

At this point, a nice example would help understand that technique:

## Step-by-Step Example

Let's imagine that we have some sort of legacy system, that is a social network and allows for users to receive notifications on things that happened. And you need to change slightly what "Followed" notification means. The code looks like this and it doesn't have any tests:

```ruby
class User
  def notifications
    notifications = Database
      .where("notifications") do |x|
        (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
        (x[1][0] == "favorited_notification" && StatusUpdate.find(x[1][2].to_i).owner_id == id) ||
        (x[1][0] == "replied_notification" && StatusUpdate.find(x[1][2].to_i).owner_id == id) ||
        (x[1][0] == "reposted_notification" && StatusUpdate.find(x[1][2].to_i).owner_id == id)
      end.map do |row|
        id, values = row
        kind = values[0]

        if kind == "followed_notification"
          {
            kind: kind,
            follower: User.find(values[1].to_i),
            user: User.find(values[2].to_i),
          }
        elsif kind == "favorited_notification"
          {
            kind: kind,
            favoriter: User.find(values[1].to_i),
            status_update: StatusUpdate.find(values[2].to_i),
          }
        elsif kind == "replied_notification"
          {
            kind: kind,
            sender: User.find(values[1].to_i),
            status_update: StatusUpdate.find(values[2].to_i),
            reply: StatusUpdate.find(values[3].to_i),
          }
        elsif kind == "reposted_notification"
          {
            kind: kind,
            reposter: User.find(values[1].to_i),
            status_update: StatusUpdate.find(values[2].to_i),
          }
        end
      end

    Analytics.tag({name: "fetch_notifications", count: notifications.count})
    notifications
  end
end
```

### Narrow & Isolate

First step is to isolate this code and make it testable. For this we need to find a low-risk way to refactor all dependencies that this code has:

- `Database.where`,
- `StatusUpdate.find`,
- `User.find`, and
- `Analytics.tag`.

We can promote these things to the following roles:

- `Database.where` => `@table_reader.where`,
- `StatusUpdate.find` => `@status_update_finder.where`,
- `User.find` => `@user_finder.find`, and
- `Analytics.tag` => `@event_tagger.tag`.

We should be able to have these default to their original values and also allow to substitute different implementation from the test. Also, it is helpful to pull out this method into the clean environment, where accessing a dependency, without us substituting it - is not possible, for example in a separate code-base, so that we can write a test "it works" and see what fails. First failure is of course all our referenced classes are missing. Let's define all of them without any implementation and make them fail in runtime if we ever call them from our testing environment:

```ruby
class Database
  def self.where(table_name)
    fail "Database:nope"
  end
end

class Analytics
  def self.tag(event)
    fail "Analytics:nope"
  end
end

class StatusUpdate
  def self.find(id)
    fail "StatusUpdate:nope"
  end
end

class User
  # .. def notifications ..

  def self.find(id)
    fail "User:nope"
  end
end
```

In our tests we need to implement our substitutes. For now, they all should be just simple double/stubs:

```ruby
class FakeTableReader
  def where(table_name, &filter)
    [[nil, ["favorited_notification"]]]
  end
end

class FakeEventTagger
  def tag(event)

  end
end

class FakeUserFinder
  def find(id)
    User.new
  end
end

class FakeStatusUpdateFinder
  def find(id)
    StatusUpdate.new
  end
end
```

Then, we should write the simplest test, that sets up the stage and substitutes all the collaborators and runs the function under the test (no assertion, we are just verifying that we indeed substituted everything right):

```ruby
it "works" do
  fake_table_reader = FakeTableReader.new
  fake_event_tagger = FakeEventTagger.new
  fake_user_finder = FakeUserFinder.new
  fake_status_update_finder = FakeStatusUpdateFinder.new

  user = User.new
             .with_table_reader(fake_table_reader)
             .with_event_tagger(fake_event_tagger)
             .with_user_finder(fake_user_finder)
             .with_status_update_finder(fake_status_update_finder)

  user.notifications
end
```

Since we haven't defined all the `with_*` methods yet, let's define them now and also define getters for respective instance variables (properties):

```ruby
class User
  # ...

  def table_reader
    @table_reader ||= Database
  end

  def event_tagger
    @event_tagger ||= Analytics
  end

  def user_finder
    @user_finder || User
  end

  def status_update_finder
    @status_update_finder || StatusUpdate
  end

  def with_table_reader(table_reader)
    @table_reader = table_reader
    self
  end

  def with_event_tagger(event_tagger)
    @event_tagger = event_tagger
    self
  end

  def with_user_finder(user_finder)
    @user_finder = user_finder
    self
  end

  def with_status_update_finder(status_update_finder)
    @status_update_finder = status_update_finder
    self
  end
end
```

If we run our test, it should fail with `RuntimeError: Database:nope` in here:

```ruby
def notifications
  notifications = Database            # <<<<<<
    .where("notifications") do |x|
```

To fix that, we will need to replace `Database` with `table_reader` getter. This will fix current error and we will get the next one: `RuntimeError User:nope`. Following all these errors and replacing direct dependencies with getters we will finally get a Green Bar (passing test). And our function under the test will look like that:

```ruby
class User
  def notifications
    notifications = table_reader
      .where("notifications") do |x|
        (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
            (x[1][0] == "favorited_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id) ||
            (x[1][0] == "replied_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id) ||
            (x[1][0] == "reposted_notification" && status_update_finder.find(x[1][2].to_i).owner_id == id)
      end.map do |row|
        id, values = row
        kind = values[0]

        if kind == "followed_notification"
          {
              kind: kind,
              follower: user_finder.find(values[1].to_i),
              user: user_finder.find(values[2].to_i),
          }
        elsif kind == "favorited_notification"
          {
              kind: kind,
              favoriter: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
          }
        elsif kind == "replied_notification"
          {
              kind: kind,
              sender: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
              reply: status_update_finder.find(values[3].to_i),
          }
        elsif kind == "reposted_notification"
          {
              kind: kind,
              reposter: user_finder.find(values[1].to_i),
              status_update: status_update_finder.find(values[2].to_i),
          }
        end
      end

    event_tagger.tag({name: "fetch_notifications", count: notifications.count})
    notifications
  end

  # ...
end
```

Structure and logic of the function didn't change at all, but now all the dependencies are injectable and can be used to nicely test it. This concludes the first step - narrow & isolate. Now it is time to select a group of knowledge bits that we would like to cover with tests. Since we want to change how `followed_notification`s behave we might as well start testing there.

### Trying to Understand & Writing 1st Test

The group of knowledge bits that are related to `followed_notification` looks like this:

```ruby
    notifications = table_reader
      .where("notifications") do |x|
        (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
        # ...
      end.map do |row|
        id, values = row
        kind = values[0]

        if kind == "followed_notification"
          {
              kind: kind,
              follower: user_finder.find(values[1].to_i),
              user: user_finder.find(values[2].to_i),
          }
        elsif #...
          # ...
        end
      end

    # ...
    notifications
```

Now we want to write a test. At the first thought, something like:

```ruby
it "obtains followed notifications for the user" do
  # first create a user with all fakes (extracted to a helper method)
  user = create_user_with_fakes

  # then instruct our table reader fake to return prepared data
  fake_table_reader
      .insert("notifications",
              [1001, ["followed_notification", 2001, 3001]])

  # and expect that we have exactly one notification
  expect(user.notifications.count).to eq(1)
end

def create_user_with_fakes
  User.new(567)
      .with_table_reader(fake_table_reader)
      .with_event_tagger(fake_event_tagger)
      .with_user_finder(fake_user_finder)
      .with_status_update_finder(fake_status_update_finder)
end

class FakeTableReader
  def insert(table_name, row)
    tables(table_name) << row
  end

  def tables(table_name)
    @tables ||= {}
    @tables[table_name] ||= []
  end

  def where(table_name, &filter)
    tables(table_name).select(&filter)
  end
end
```

### Making It Pass

This test fails right away - we don't have any notifications. This is strange. Let's take a closer look on the filtering that we are doing:

```ruby
(x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

I believe, we have satisfied the first part of this condition, but not the second one. User id is not the same as 3rd element of this row. Let's make them same:

```ruby
fake_table_reader
    .insert("notifications",
            [1001, ["followed_notification", 2001, 567]])
                                               # ^ here ^
```

And this fails again! This code just keeps proving our assumptions wrong. I think we need to take a careful look at that `it.to_s`. `.to_s` - is a conversion to string, so the foreign key actually is stored as a string (who could have thought?). Let's try to make it work:

```ruby
fake_table_reader
    .insert("notifications",
            [1001, ["followed_notification", 2001, "567"]])
                                                # ^ here ^
```

### Applying Mutational Testing

And if we run our tests, they pass! Great, now we know that this function is capable of obtaining some followed notifications. Of course our coverage right now is super low. Let's apply mutational testing to it. We should start from the condition:

```ruby
(x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

First, let's replace the whole thing with `false`:

```ruby
false ||
```

And the test fails - mutant does not survive - our tests are covering for this mutation. Let's try another one: replace the whole thing with `true`:

```ruby
true ||
```

Our tests pass - mutant survives - this is a failing test for our tests. In this case it is reasonable to write a new test for a case, when the whole filtering expression should yield `false` - when we have notifications of invalid kind:

```ruby
it "ignores notifications of invalid kind" do
  user = create_user_with_fakes

  fake_table_reader
      .insert("notifications",
              [1001, ["invalid", 2001, "567"]])

  expect(user.notifications.count).to eq(0)
end
```

As a result we shouldn't get any notifications. After running we see that our test fail. Great! This mutant no longer survives. Let's see if our tests will pass when we undo the mutation:

```ruby
(x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

And they all pass! Next mutation is inverting the whole condition:

```ruby
! (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

And all our tests are RED. Which means that this mutant does not survive and the test for our test is green. Now, we should dig deeper in the parts of the condition itself:

- `x[1][0] == "followed_notification"`: replacing with `true`, `false`, and inverting; also, changing numeric and string constants; These all changes didn't produce any surviving mutants, so no new tests need to be introduced.
- `x[1][2] == id.to_s`: replacing with `true`, `false` and inverting; also, changing numeric constants.

Replacing `x[1][2] == id.to_s` with `true`, apparently, leaves all our tests passing - a mutant that survives - a failing test for our test suite. It is time to add this test - when we have notifications of some different user:

```ruby
it "ignores notifications of different user" do
  user = create_user_with_fakes

  fake_table_reader
      .insert("notifications",
              [1001, ["followed_notification", 2001, "other user"]])
                                                   # ^   here   ^

  expect(user.notifications.count).to eq(0)
end
```

As you can see, having a record with different user id (in this case, even nonsensical user id) makes our test fail. Which means that this mutant no longer survives. Let's see if undoing the mutation will turn our tests GREEN:

```ruby
(... && x[1][2] == id.to_s) ||
```

And all our tests pass again. I think we are done with the condition in the filter. I would not touch the conditions that are related to different kinds of notifications, as we want to introduce changes only to "Followed" notifications. So we can dig further into the logic of our group of knowledge bits:

```ruby
id, values = row
kind = values[0]

if kind == "followed_notification"
  {
      kind: kind,
      follower: user_finder.find(values[1].to_i),
      user: user_finder.find(values[2].to_i),
  }
elsif #...
  # ...
end
```

So, we can see that we split the row into its `id` and all the other values of the notification record. And apparently, first value is responsible for kind, where we are switching on it to construct correct object (in this case just a lump of data - has map). So let's try to mutate the numeric constant in `kind = values[0]`:

```ruby
kind = values[1]
          #  ^^^
```

And all our tests still pass. This is a failing test for our test suite. We ought to write a new test now. Where we should verify that it constructs correct lumps of data:

```ruby
it "constructs correct followed notification" do
  user = create_user_with_fakes

  fake_table_reader
      .insert("notifications",
              [1001, ["followed_notification", 2001, "567"]])

  expect(user.notifications[0][:kind]).to eq("followed_notification")
end
```

And this test fails, because our `user.notifications[0]` is `nil`, because none of `if` or `elsif` matched the `kind` variable and in Ruby, by default any function returns a `nil` value. This failing test means that we no longer have surviving mutant and let's see if undoing that mutation will make our tests pass:

```ruby
kind = values[0]
          #  ^^^
```

And it does, all our tests are green now. We should continue like this, until we understand code enough and we have enough confidence in our tests, so that we can make our desired change to the code. When we thing we are done, we should integrate isolated code back to the legacy code, leaving all the fakes and injection capabilities in place. We were isolating this code only to make sure, that we are not calling any dependencies on accident (and they just work silently). While integrating it back we of course get rid of `fail "NAME:nope"` implementations of collaborators. With such approach, integrating the code back should be as simple as copy-pasting the test suite code and production code (function under the test, and injecting facilities) without copying always-failing collaborators.
