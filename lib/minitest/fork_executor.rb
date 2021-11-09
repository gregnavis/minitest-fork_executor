module Minitest
  # Minitest runs individual test cases via Minitest.run_one_method. When
  # ForkExecutor is started, we need to override it and implement the fork
  # algorithm. See the detailed comments below to understand how it's done.
  #
  # Please keep in mind we support Ruby 1.9 and hence can't use conveniences
  # offered by more modern Rubies.

  class ForkExecutor
    # #start is called by Minitest when initializing the executor. This is where
    # we override some Minitest internals to implement fork-based execution.
    def start
      # Store the reference to the original run_one_method method in order to
      # use it to actually run the test case.
      original_run_one_method = Minitest.method(:run_one_method)

      # Remove the original singleton method from Minitest in order to avoid
      # method redefinition warnings when patching it in the next step.
      class << Minitest
        remove_method(:run_one_method)
      end

      # Define a new version of run_one_method that forks, calls the original
      # run_one_method in the child process, and sends results back to the
      # parent. klass and method_name are the two parameters accepted by the
      # original run_one_method - they're the test class (e.g. UserTest) and
      # the test method name (e.g. :test_email_must_be_unique).
      Minitest.define_singleton_method(:run_one_method) do |klass, method_name|
        # Set up a binary pipe for transporting test results from the child
        # to the parent process.
        read_io, write_io = IO.pipe
        read_io.binmode
        write_io.binmode

        if Process.fork
          # The parent process responsible for collecting results.

          # The parent process doesn't write anything.
          write_io.close

          # Load the result object passed by the child process.
          result = Marshal.load(read_io)

          # Unwrap all failures from FailureTransport so that they can be
          # safely presented to the user.
          result.failures.map! { _1.failure }

          # We're done reading results from the child so it's safe to close the
          # IO object now.
          read_io.close

          # Wait for the child process to finish before returning the result.
          Process.wait
        else
          # The child process responsible for running the test case.

          # Run the test case method via the original .run_one_method.
          result = original_run_one_method.call(klass, method_name)

          # Wrap failures in FailureTransport to avoid issue when marshalling.
          # Some failures correspond to exceptions referencing unmarshallable
          # objects. For example, a PostgreSQL exception may reference
          # PG::Connection that cannot be marshalled. In those case, we replace
          # the original error with UnmarshallableError retaining as much
          # detail as possible.
          result.failures.map! { FailureTransport.new(_1) }

          # The child process doesn't read anything.
          read_io.close

          # Dump the result object to the write IO object so that it can be
          # read by the parent process.
          Marshal.dump(result, write_io)

          # We're done sending results to the parent so it's safe to close the
          # IO object now.
          write_io.close

          # Exit the child process as its job is now done.
          exit
        end

        # This value is returned ONLY in the parent process, not in the child
        # process.
        result
      end
    end

    def shutdown
      # Nothing to do here but required by Minitest. In a future version, we may
      # reinstate the original Minitest.run_one_method here.
    end

    # A Minitest Failure transport class enabling passing non-marshallable
    # objects (e.g. IO or sockets) via Marshal. The basic idea is replacing
    # Minitest failures referencing unmarshallable objects with
    # UnmarshallableError retaining as much detail as possible.
    class FailureTransport
      attr_reader :failure

      def initialize(failure)
        @failure = failure
      end

      def marshal_dump
        Marshal.dump(failure)
      rescue TypeError
        # CAREFUL! WE'RE MODIFYING FAILURE IN PLACE UNDER THE ASSUMPTION THAT
        # IT LIVES IN A MEMORY SPACE OF A SHORT-LIVED PROCESS, NAMELY THE CHILD
        # PROCESS RESPONSIBLE FOR RUNNING A SINGLE TEST. IF THIS ASSUMPTION IS
        # VIOLATED THEN AN ALTERNATIVE APPROACH (E.G. DUPLICATING THE FAILURE)
        # MIGHT BE NECESSARY.
        failure.error = UnmarshallableError.new(failure.error)
        Marshal.dump(failure)
      end

      def marshal_load(dump)
        @failure = Marshal.load(dump)
      end
    end

    # An always marshallable exception class that can be derived from another
    # (potentially non-marshallable exception). It's actually not intended to be
    # raised but merely instantiated when passing Minitest failures from the
    # runner to the reporter.
    class UnmarshallableError < RuntimeError
      def initialize(exc)
        super(<<MESSAGE)
An unmarshallable error has occured. Below is its best-effort representation.
In order to receive the error itself, please disable Minitest::ForkExecutor.

Error class:
#{exc.class.name}

Error message:
#{exc.message}

Attributes:
#{exc.instance_variables.map do |name|
  "  #{name} = #{exc.instance_variable_get(name).inspect}"
end.join("\n")}

END OF ERROR MESSAGE (ORIGINAL BACKTRACE MAY FOLLOW)
MESSAGE

        set_backtrace(exc.backtrace)
      end
    end
  end
end
