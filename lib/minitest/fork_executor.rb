module Minitest
  class ForkExecutor
    # Minitest runs individual test cases via Minitest.run_one_method. When
    # ForkExecutor is started, we need to override it and implement the fork
    # algorithm. See the detailed comments below to understand how it's done.
    #
    # Please keep in mind we support Ruby 1.9 and hence can't use conveniences
    # offered by more modern Rubies.
    def start
      # Store the reference to the original run_one_method singleton method.
      original_run_one_method = Minitest.method(:run_one_method)

      # Remove the original singleton method from Minitest in order to avoid
      # method redefinition warnings when patching it in the next step.
      class << Minitest
        remove_method(:run_one_method)
      end

      # Define a new version of run_one_method that forks, calls the original
      # run_one_method in the child process, and sends results back to the
      # parent.
      Minitest.define_singleton_method(:run_one_method) do |klass, method_name|
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
          result = original_run_one_method.call(klass, method_name)

          read_io.close
          Marshal.dump(result, write_io)
          write_io.close
          exit
        end

        result
      end
    end

    def shutdown
      # Nothing to do here but required by Minitest. In a future version, we may
      # reinstate the original Minitest.run_one_method here.
    end
  end
end
