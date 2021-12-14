# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barzahlen/version'

Gem::Specification.new do |spec|
  # For explanations see http://docs.rubygems.org/read/chapter/20
  spec.name          = 'barzahlen'
  spec.version       = Barzahlen::VERSION
  spec.authors       = ['David Leib', 'Tobias Schoknecht']
  spec.email         = ['tobias.schoknecht@viafintech.com']
  spec.description   = 'This is a ruby gem to access the viafintech API v2.'
  spec.summary       = 'Client gem for viafintech API v2.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rack-test', '~> 1.1.0'
  spec.add_development_dependency 'rake',      '~> 13.0.6'
  spec.add_development_dependency 'rspec',     '~> 3.10.0'

  spec.add_runtime_dependency     'grac',      '~> 4.0.1'

end
