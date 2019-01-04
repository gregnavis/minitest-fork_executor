Gem::Specification.new do |s|
  s.name        = 'minitest-fork_executor'
  s.version     = '1.0.0'
  s.date        = '2019-01-03'
  s.summary     = 'Near-perfect process-level test case isolation.'
  s.description = 'Run each test_* method in a separate process thus eliminating test case interference.'
  s.authors     = ['Greg Navis']
  s.email       = 'contact@gregnavis.com'

  s.files       = ['lib/minitest/fork_executor.rb']
  s.test_files  = Dir['test/**/*']

  s.add_dependency 'minitest'

  s.add_development_dependency 'rake'

  s.homepage    = 'https://github.com/gregnavis/minitest-fork_executor'
  s.license     = 'MIT'
end
