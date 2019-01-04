# Minitest Fork Executor

Achieve near-perfect process-level test case isolation by running each and
every test case in a separate process.

The gem operates at **the method-level**, not the class-level. This means that
running a test class `MyTest` with test methods `test_one`, `test_two` and
`test_three` will run each of these `test_*` methods in a separate process.

[<img src="https://travis-ci.org/gregnavis/minitest-fork_executor.svg?branch=master" alt="Build Status" />](https://travis-ci.org/gregnavis/minitest-fork_executor)

## Installation

Install either via Ruby Gems

```
gem install minitest-fork_executor
```

or add to `Gemfile`:

```ruby
gem 'minitest-fork_executor', group: :test
```

Then configure Minitest to use it by adding the following to `test_helper.rb`
or a similar file:

```ruby
Minitest.parallel_executor = Minitest::ForkExecutor.new
```

## Why?

The gem is motivated by my work on
[`active_record_doctor`](https://github.com/gregnavis/active_record_doctor).
Each test case in the test suite defines an Active Record model dynamically and
it turned out these models aren't garbage collected properly. The most likely
reason for that was `ActiveSupport::DescendantsTracker` in Rails. The problem
was compounded by testing against multiple versions of Ruby and Rails. Fixing
the problem in one configuration caused it to reoccur in another one.

I wasn't able to use already-existing solutions like `minitest-parallel_fork`
because they fork for each class but then run each `test_*` methods in a class
in the same process. This wasn't granular enough to solve my issue and I wanted
to avoid splitting my test suite into multiple single-method test classes.

Debugging and fixing the issue wasn't a top priority for me as I had already
invested hours in finding a solution. My goal was to release
`active_record_doctor` and insulate myself from similar occurences in the
future.

## Author

This gem is developed and maintained by [Greg Navis](mailto:contact@gregnavis.com).
