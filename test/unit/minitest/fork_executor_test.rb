require 'tempfile'

require 'minitest/autorun'
require 'minitest/fork_executor'

Minitest.parallel_executor = Minitest::ForkExecutor.new

# This test may seem to be more complicated than necessary but it's actually
# not. If we had only one test method then an implementation that forked an
# run *all* tests in the fork would pass the test.
#
# We need to ensure that:
#
# 1. Different test methods are run in different processes - hence two tests.
# 2. These processes are different from the parent process that spawned the
#    test suite - hence recording @@parent_pid at the top.
class ForkTest < Minitest::Test
  @@log = Tempfile.new('pid')
  @@parent_pid = Process.pid

  def test_run_in_process_one
    log_and_assert
  end

  def test_run_in_process_two
    log_and_assert
  end

  private

  def log_and_assert
    @@log.seek(0, IO::SEEK_END)
    @@log.write("#{Process.pid}\n")
    @@log.rewind

    pids = @@log.readlines.map(&:chop).map(&:to_i)
    if pids.count == 2
      assert_equal 2, pids.uniq.count
      refute pids.include?(@@parent_pid)
    end
  end
end
