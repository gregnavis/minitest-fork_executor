require 'tempfile'

require 'minitest/autorun'
require 'minitest/fork_executor'

Minitest.parallel_executor = Minitest::ForkExecutor.new

class UnmarshallableException < RuntimeError
  def initialize(io)
    super("Unmarshallable test exception")
    @io = io
  end
end

class UnmarshallableTest < Minitest::Test
  def test_unmarshallable_wrapping
    # We'd like to see a backtrace in the output hence several raise_in_* calls.
    raise_in_2
  end

  private

  def raise_in_2
    raise_in_1
  end

  def raise_in_1
    raise_in_0
  end

  def raise_in_0
    raise UnmarshallableException.new($stdout)
  end
end
