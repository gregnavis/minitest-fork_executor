begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'tmpdir'
require 'rake/testtask'

Rake::TestTask.new(:"test:unit") do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/unit/**/*_test.rb'
  t.verbose = false
end

EXPECTED_ERROR = <<ERROR
1) Error:
UnmarshallableTest#test_unmarshallable_wrapping:
Minitest::ForkExecutor::UnmarshallableError: An unmarshallable error has occured. Below is its best-effort representation.
In order to receive the error itself, please disable Minitest::ForkExecutor.

Error class:
UnmarshallableException

Error message:
Unmarshallable test exception

Attributes:
  @io = #<IO:<STDOUT>>

END OF ERROR MESSAGE (ORIGINAL BACKTRACE MAY FOLLOW)

    test/acceptance/unmarshallable_test.rb:32:in `raise_in_0'
    test/acceptance/unmarshallable_test.rb:28:in `raise_in_1'
    test/acceptance/unmarshallable_test.rb:24:in `raise_in_2'
    test/acceptance/unmarshallable_test.rb:18:in `test_unmarshallable_wrapping'

1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
ERROR

namespace :test do
  task :acceptance do
    Dir.mktmpdir do |dir|
      path = "#{dir}/unmarshallable_test.out"
      ruby(%[-Ilib test/acceptance/unmarshallable_test.rb >& #{path} || true])

      output = File.read(path)

      if !output.end_with?(EXPECTED_ERROR)
        $stderr.puts("Acceptance test failure with the following output:\n\n#{output}")
        exit(1)
      end
    end
  end
end

task :test => [:"test:unit", :"test:acceptance"]

task default: :test
