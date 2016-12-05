title: Understanding Legacy Code Using Explorative Test-Driven Development Technique.

Today we are going to learn how to eliminate the fear of changing legacy code. We will learn how to confidently and in small iterations understand the legacy code better while increasing the test coverage in the process. While code examples are in Ruby programming language, the technique applied is language-agnostic.

<!-- more -->

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

I think the idea "Knowledge in Production Code" should be more or less precise. More interesting is what we can do with knowledge in our system: we can re-organize knowledge differently keeping all the behaviors of the system - everyone calls this Refactoring nowadays; or do the opposite: change bits of knowledge without modifying the structure of the code - we will call one such change a Mutation:

## Mutation

Mutation - granular change of the knowledge in the system that changes the behavior of the application. Let's take a look at the simple example:

```ruby
if cell_is_alive
  do_this
else
  do_some_other_thing
end
```

This code is maybe a part of some cell organism simulation (like Game Of Life or similar). Let's see which different mutations can be applied here:

- change the `if` condition always to be `true`: `if true ...`,
- change the `if` condition always to be `false`: `if false ...`,
- invert the `if` condition: `if !cell_is_alive`,
- commenting out the `if` body: `# do_this`,
- commenting out the `else` body: `# do_some_other_thing`.

With that done, let's take a look at how production code and its test suite relate to each other.

## Code and Test Suite Relationship

So, how does the test suite affect production code? First, it makes sure the production code is correct. Also, good test suite enables quick and ruthless refactoring by eliminating (or minimizing) the risks of breaking it. Well-crafted test suite gives us the power and courage to introduce changes. Also, test code always couples to the production code it is testing in one way or another.

Okay, how does the production system affect its test suite? As tests couple to the production code they test, the changes in production system may cause ripple effects on its test suite. Practically speaking, a mutation should always lead to a test failure if the test suite is good enough because its test suite should verify every tiny bit of knowledge in the production code (except, maybe, some configuration).

Such knowledge change is an act of assertion about the presence of the test. When information is covered by test suite well, there should be a test failure. If, after the introduction of the mutation, there is no test failure, this is a failed assertion about test presence or correctness. So one might say:

> Knowledge Change is a Test for the Test

Moreover, that is a fascinating idea since it implies we can use production code can as a test suite for its test suite, which may enable TDD-like iterative development of the test suite that does not exist.

So far, we have covered the idea of knowledge in the production code, explored ways of modifying this information in a way that changes the behavior - we call it a mutation, and also we explored the mirror-like relation between production code and its test suite. We have still much ground to cover, let's dive in:

## Most Useful Coverage Metric

There is a few well-known test coverage metrics that are being used quite often by software engineering teams, such as:

- Line coverage, and
- Branch coverage.

There is another one, called Path coverage - it is about coverage of all possible code paths in the system, which quickly becomes impractical as the application size grows because of the exponential growth of the amount of these different code paths.

Line coverage and Branch coverage (also, path coverage) all share one major problem - covered line/branch/path does not mean test suite verifies it - only executes it. Great example: remove all the assertions from your tests and the coverage metric will stay the same.

So, what if we could introduce all possible and sane mutations to our code and count how much of them cause test failure? - We will get the knowledge coverage metric. Another name for it is Test Semantic Stability, and it can range from 0% to 100%. Even 100% line/path coverage can easily yield 0% Test Semantic Stability. This metric proves that code is, indeed well-tested and verified (although, it does not say anything about tests' design and cleanliness): make one assertion incorrect, or not precise enough and the metric will go down by a few mutations.

That makes Test Semantic Stability the most useful coverage metric.

So, how do we check if our test(s) cover well some bit of knowledge in the system? We break it! - Introduce a tiny granular breaking change to that bit of knowledge. The test suite should fail. If it does not - information is not covered well enough. Moreover, that leads us to the technique that allows us to keep Semantic Test Stability up high:

## Mutational Testing

1. Narrow the scope of work to a single granular piece of knowledge.
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

First, we need to narrow our scope to a single bit of knowledge. For example, the `if` condition: `if cell_is_alive`. Then we need to introduce the mutation `if true,` and we need to make sure that there is a test failure. Let's run the test suite:

```
$ rake test
....

Finished in 0.02343 seconds (files took 0.11584 seconds to load)
4 examples, 0 failures
```

Oh no! It did not fail anywhere! That means that we have a "failing test" for our test suite. In this case, we need to add the test for the negative case:

```ruby
cell_is_alive = false
expect(did_some_other_thing).to eq(true)
```

Moreover, when we run the test suite:

```
$ rake test
....F

Finished in 0.02343 seconds (files took 0.11584 seconds to load)
5 examples, 1 failure
```

It fails! Great - that means that our test for the test suite is passing now. As the last step of this mutational testing iteration we have to return the code to its original state:

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

Moreover, they do. That concludes one iteration of the mutational testing. Usually, to accomplish any useful behavior we would like to combine many bits of knowledge. If we want to understand better how the system works, we need to focus on groups of bits of knowledge. This is what Explorative TDD technique is about:

## Explorative Test-Driven Development

The technique used to increase our understanding of the Legacy Code while enhancing its Test Semantic Stability (the most useful coverage metric). The process roughly looks like that:

1. Narrow scope to some manageable knowledge and isolate it (manageable knowledge = method/function/class/module).
2. Read, try to understand, pick a granular piece of knowledge, and make an assumption to which behavior it contributes and how.
3. Write a test to verify this assumption.
4. Make sure test passes (by altering the assumption or fixing production code (bugs)). PS: be careful with bugs, since they might be weird behaviors that are bringing someone tremendous value. When finding one of these, consult with stakeholders if that is a bug or a feature.
5. Apply Mutational Testing to each related granular piece of knowledge to verify that the understanding (and the test) is correct (this may introduce more tests).
6. Go back to 2

At this point, a nice example would help understand that technique:

## Step-by-Step Example

Let's imagine that we have some legacy system, that is a social network and allows for users to receive notifications on things that happened. Moreover, you need to change slightly what "Followed" notification means. The code looks like this, and it does not have any tests:

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

The first step is to isolate this code and make it testable. For this we need to find a low-risk way to refactor all dependencies that this code has:

- `Database.where`,
- `StatusUpdate.find`,
- `User.find`, and
- `Analytics.tag`.

We can promote these things to the following roles:

- `Database.where` => `@table_reader.where`,
- `StatusUpdate.find` => `@status_update_finder.where`,
- `User.find` => `@user_finder.find`, and
- `Analytics.tag` => `@event_tagger.tag`.

We should be able to have these default to their original values and also allow to substitute different implementation from the test. Also, it is helpful to pull out this method into the clean environment, where accessing a dependency, without us substituting it - is not possible, for example in a separate code-base, so that we can write a test "it works" and see what fails. The first failure is, of course, all our referenced classes are missing. Let's define all of them without any implementation and make them fail at runtime if we ever call them from our testing environment:

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

In our tests, we need to implement our substitutes. For now, they all should be just simple double/stubs:

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

Then, we should write the simplest test, that sets up the stage and substitutes all the collaborators and runs the function under the test (no assertion, we are just verifying that we indeed replaced everything right):

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

Since we have not defined all the `with_*` methods yet, let's define them now and also define getters for particular instance variables (properties):

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

To fix that, we will need to replace `Database` with `table_reader` getter. That will correct the current error, and we will get the next one: `RuntimeError User:nope`. Following all these failures and replacing direct dependencies with getters we will finally get a Green Bar (passing the test). Moreover, our function under the test will look like that:

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

Structure and logic of the function did not change at all, but now all the dependencies are injectable and can be used to test it nicely. That concludes the first step - narrow & isolate. Now it is time to select a group of knowledge bits that we would like to cover with tests. Since we want to change how `followed_notification` is behaving, we might as well start checking there.

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

I believe, we have satisfied the first part of this condition, but not the second one. The user id is not the same as the 3rd element of this row. Let's make them same:

```ruby
fake_table_reader
    .insert("notifications",
            [1001, ["followed_notification", 2001, 567]])
                                               # ^ here ^
```

Moreover, this fails again! This code just keeps proving our assumptions wrong. I think we need to take a careful look at that `it.to_s`. `.to_s` is a conversion to string, so the foreign key is stored as a string (who could have thought?). Let's try to make it work:

```ruby
fake_table_reader
    .insert("notifications",
            [1001, ["followed_notification", 2001, "567"]])
                                                # ^ here ^
```

### Applying Mutational Testing

Moreover, if we run our tests, they pass! Great, now we know that this function is capable of obtaining some followed notifications. Of course, our coverage right now is super small. Let's apply mutational testing to it. We should start from the condition:

```ruby
(x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

First, let's replace the whole thing with `false`:

```ruby
false ||
```

Moreover, the test fails - mutant does not survive - our tests are covering for this mutation. Let's try another one: replace the whole thing with `true`:

```ruby
true ||
```

Our tests pass - mutant survives - this is a failing test for our tests. In this case, it is reasonable to write a new test for a case, when the full filtering expression should yield `false` - when we have notifications of an invalid kind:

```ruby
it "ignores notifications of an invalid kind" do
  user = create_user_with_fakes

  fake_table_reader
      .insert("notifications",
              [1001, ["invalid", 2001, "567"]])

  expect(user.notifications.count).to eq(0)
end
```

As a result, we should not get any notifications. After running, we see that our test fail. Great! This mutant no longer survives. Let's see if our tests will pass when we undo the mutation:

```ruby
(x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

And they all pass! Next mutation is inverting the whole condition:

```ruby
! (x[1][0] == "followed_notification" && x[1][2] == id.to_s) ||
```

Moreover, all our tests are RED. Which means that this mutant does not survive and the test for our test is green. Now, we should dig deeper into the parts of the condition itself:

- `x[1][0] == "followed_notification"`: replacing with `true`, `false`, and inverting it; also, changing numeric and string constants; These all changes did not produce any surviving mutants, so we do not need to introduce new tests.
- `x[1][2] == id.to_s`: replacing with `true`, `false` and inverting it; also, changing numeric constants.

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

As you can see, having a record with the different user id (in this case, even nonsensical user id) makes our test fail, which means that this mutant no longer survives. Let's see if undoing the mutation will turn our tests GREEN:

```ruby
(... && x[1][2] == id.to_s) ||
```

Moreover, all our tests pass again. I think we have finished testing the condition in the filter. I would not touch the conditions that are related to different kinds of notifications, as we want to introduce changes only to "Followed" notifications. So we can dig further into the logic of our group of knowledge bits:

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

So, we can see that we split the row into its `id` and all the other values of the notification record. Moreover, apparently, the first value is responsible for the kind, where we are switching on it to construct correct object (in this case just a lump of data - hash map). So let's try to mutate the numeric constant in `kind = values[0]`:

```ruby
kind = values[1]
          #  ^^^
```

Moreover, all our tests still pass. That is a failing test for our test suite. We ought to write a new test now. Where we should verify that it constructs correct lumps of data:

```ruby
it "constructs correct followed notification" do
  user = create_user_with_fakes

  fake_table_reader
      .insert("notifications",
              [1001, ["followed_notification", 2001, "567"]])

  expect(user.notifications[0][:kind]).to eq("followed_notification")
end
```

Moreover, this test fails, because our `user.notifications[0]` Is `nil`, because none of `if` or `elsif` matched the `kind` variable and in Ruby, by default any function returns a `nil` value. This failing test means that we no longer have surviving mutant and let's see if undoing that mutation will make our tests pass:

```ruby
kind = values[0]
          #  ^^^
```

Moreover, it does, all our tests are green now. We should continue like this until we understand code enough and have enough confidence in our tests so that we can make our desired change to the system. When we think we have finished, we should integrate isolated code back to the legacy system, leaving all the fakes and injection capabilities in place. We were separating this code only to make sure, that we are not calling any dependencies on accident (while they just work silently). While integrating it back we, of course, get rid of `fail "NAME:nope"` implementations of collaborators. With such approach, integrating the code back should be as simple as copy-pasting the test suite code and production code (function under the test, and injecting facilities) without copying always-failing collaborators.

We will have to wrap up the example, and if you, my reader, would like to continue applying Explorative TDD to this code, you can find the code here: https://github.com/waterlink/explorative-tdd-blog-post (specifically, `spec/user_spec.rb`). The function originates from this example project: https://github.com/waterlink/lemon

## Can Explorative TDD Help Me Outside of Legacy Code?

The answer is yes! I use Explorative TDD (as well as mutational testing) in following cases:

- During big refactorings, such as Extract class/module/package. The technique helps you quickly understand which tests have to be moved as well to the new test suite (only if you want to transfer them).
- When refactoring tests. The technique helps you to verify if your tests are still working as they are intended to and if they are still semantically stable (they catch a majority of mutants).
- To measure rigidity of test-to-code coupling. If a single mutation leads to half of your test suite failing (even irrelevant tests) - tests need refactoring.

## Bottom Line

Today we have learned about concepts like "Knowledge in production code" and "Mutation." Also, we learned what Test Semantic Stability is the best code coverage metric. We have seen Mutational Testing and Explorative TDD techniques at work. Moreover, we could start applying these techniques (after some practice) to stop fearing the legacy code and just handle it as some tedious routine operation.

## Thanks

Thank you for reading, my dear reader. If you liked it, please share this article on social networks and follow me on twitter: [@waterlink000](https://twitter.com/waterlink000).

If you have any questions or feedback for me, don’t hesitate to reach me out on Twitter: [@waterlink000](https://twitter.com/waterlink000).
