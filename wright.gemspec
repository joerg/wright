require File.expand_path('../lib/wright/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Sebastian Boehm']
  gem.email         = ['sebastian@sometimesfood.org']
  gem.license       = 'MIT'
  gem.summary       = 'A lightweight config management library'
  gem.homepage      = 'https://github.com/sometimesfood/wright'
  gem.description   = <<EOS
Wright is a lightweight configuration management library.
EOS

  gem.files         = Dir['{bin,lib,spec}/**/*',
                          'man/wright.1',
                          'Rakefile',
                          'README.md',
                          'CONTRIBUTING.md',
                          'NEWS.md',
                          'LICENSE'] & `git ls-files -z`.split("\0")
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'wright'
  gem.require_paths = ['lib']
  gem.version       = Wright::VERSION

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency 'minitest', '~> 5.6.1'
  gem.add_development_dependency 'minitest-stub-const', '~> 0.4'
  gem.add_development_dependency 'fakefs', '~> 0.6.7'
  gem.add_development_dependency 'fakeetc', '~> 0.2.0'
  gem.add_development_dependency 'rake', '~> 10.4.2'
  gem.add_development_dependency 'yard', '~> 0.8.7.6'
  gem.add_development_dependency 'simplecov', '~> 0.10.0'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'rubocop', '~> 0.31.0'
end
