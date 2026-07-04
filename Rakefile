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

EXPECTED_ERRORS = [
  "UnmarshallableTest#test_unmarshallable_wrapping:",
  "UnmarshallableException: Unmarshallable test exception",
  "test/acceptance/unmarshallable_test.rb:32:in",
  "raise_in_0",
  "test/acceptance/unmarshallable_test.rb:28:in",
  "raise_in_1",
  "test/acceptance/unmarshallable_test.rb:24:in",
  "raise_in_2",
  "test/acceptance/unmarshallable_test.rb:18:in",
  "test_unmarshallable_wrapping",
]

namespace :test do
  task :acceptance do
    Dir.mktmpdir do |dir|
      path = "#{dir}/unmarshallable_test.out"
      ruby(%[-Ilib test/acceptance/unmarshallable_test.rb > #{path} 2>&1 || true])

      output = File.read(path)

      if !EXPECTED_ERRORS.all? { output.include?(_1) }
        $stderr.puts("Acceptance test failure with the following output:\n\n#{output}")
        exit(1)
      end
    end
  end
end

task :test => [:"test:unit", :"test:acceptance"]

task default: :test
