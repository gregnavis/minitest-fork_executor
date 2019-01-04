module Minitest
  class ForkExecutor
    def start
      # Minitest runs test cases via Minitest.run_one_method. Each test case
      # in a test class is run separately. We need to override that method and
      # fork there. run_one_method is a method on the Minitest module so we need
      # to *prepend* our version so that it's called first.
      metaclass = (class << Minitest; self; end)
      metaclass.prepend ClassMethods
    end

    def shutdown
      # Nothing to do here but required by Minitest.
    end

    module ClassMethods
      # The updated version of Minitest.run_one_method that forks before
      # actually running a test case, makes the child run it and send the result
      # to the parent process.
      def run_one_method klass, method_name
        read_io, write_io = IO.pipe
        read_io.binmode
        write_io.binmode

        if fork
          # Parent: load the result sent from the child

          write_io.close
          result = Marshal.load(read_io)
          read_io.close

          Process.wait
        else
          # Child: just run normally, dump the result, and exit the process to
          # avoid double-reporting.
          result = super

          read_io.close
          Marshal.dump(result, write_io)
          write_io.close
          exit
        end

        result
      end
    end
  end
end
