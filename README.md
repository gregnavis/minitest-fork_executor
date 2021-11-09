# Minitest Fork Executor

If you're struggling with state leaking between test cases then
`minitest-fork_executor` can help you alleviate the pain by **running each
test case in a separate process** so that no state can be leaked between them.

[![Build Status](https://github.com/gregnavis/minitest-fork_executor/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/gregnavis/minitest-fork_executor/actions/workflows/test.yml)

## Installation

Install via Ruby Gems:

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

From now on, each test method will be run in a separate process.

## Rationale and Prior Art

When working on [`active_record_doctor`](https://github.com/gregnavis/active_record_doctor)
I had to deal with order-dependent test cases caused by insufficient garbage
collection of dynamically defined Active Record classes. The extent of the
problem was compounded by supporting multiple versions of Ruby and Rails.

The proper solution to the problem would be to fix the offending Rails code but
it would be a time-consuming distraction from work I wanted done on `active_record_doctor`.
I decided to work around the problem by running each test case in a separate
process and turned the solution into a standalone gem.

`minitest-parallel_fork` is a similar gem but works at a class-level instead of
test-case level. It means `test_*` methods defined on the same test class can
still leak state. The problem could be avoided by splitting each test class
into multiple single-method test classes (one for each `test_*` method) however
I decided against that solution in order to maintain higher test cohesion.
## Author

This gem is developed and maintained by [Greg Navis](mailto:contact@gregnavis.com).
