# Minitest Fork Executor

`minitest-fork_executor` helps you avoid leaking state between individual
`test_*` methods and `*Test` classes by running each test method in a separate
process.

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

Thats it! From now on, each test method will be run in a separate process.

## Caveat

When `minitest-fork_executor` some exceptions raised during test case execution
may be reported as a different exception class. This is by design and was
required to overcome limitations imposed by certain implementation choices.

`minitest-fork_executor` run each test method in a separate process. The
result, including number of assertions and exceptions (if any) raised during
execution, must be passed to the parent process for reporting. We use `Marshal`
to communicate between processes using a pipe object.

Problems araise when the test method raises an exception that references an
object unsupported by `Marshal`. For example, a database exception may contain
a reference to the database connection socket, which cannot be marshalled. To
overcome that limitation, we convert non-marshallable exceptions into a
different class, called `Minitest::ForkExecutor::UnmarshallableError` that is
guaranteed to be marshallable and which tries to retain as much original
information as possible.

## Rationale

The idea for for a new forker came when I was working on [`active_record_doctor`](https://github.com/gregnavis/active_record_doctor).
I had just set up a test suite against multiple versions of Ruby and Rails but
couldn't get rid of random test case failures. Further troubleshooting indicated
the problem lied in insufficient garbage collection, most likely caused by a bug
deep in the guts of Active Support. Resolving the problem for a specific
Ruby/Rails version combination would make the problem appear in different
versions.

Submitting a patch to Active Support wouldn't be a complete solution because
Rails 4.2, which I wanted to support, had already reached end-of-life. That,
plus my limited time budget for open source work made `minitest-fork_executor`
an economical idea.

## Prior Art

`minitest-parallel_fork` is a similar gem but works at a class-level instead of
test-case level. It means `test_*` methods defined on the same test class can
still leak state. The problem could be avoided by splitting each test class
into multiple single-method test classes (one for each `test_*` method) however
I decided against that solution in order to maintain higher test class cohesion.

## Author

This gem is developed and maintained by [Greg Navis](mailto:contact@gregnavis.com).
