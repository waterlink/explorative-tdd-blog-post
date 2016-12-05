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
