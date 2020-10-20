# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barzahlen/version'

Gem::Specification.new do |spec|
  # For explanations see http://docs.rubygems.org/read/chapter/20
  spec.name          = 'barzahlen'
  spec.version       = Barzahlen::VERSION
  spec.authors       = ['David Leib']
  spec.email         = ['david.leib@barzahlen.de']
  spec.description   = 'This is a ruby gem to access the Barzahlen API v2.'
  spec.summary       = 'Client gem for API Barzahlen v2.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rack-test', '~> 0.6.3'
  spec.add_development_dependency 'rake',      '~> 13.0.1'
  spec.add_development_dependency 'rspec',     '~> 3.2.0'
  spec.add_development_dependency 'rubocop',   '~> 0.93.1'

  spec.add_runtime_dependency     'grac', '~> 2.2.1'
end
