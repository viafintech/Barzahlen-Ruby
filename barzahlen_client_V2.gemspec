# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'barzahlen_v2/version'

Gem::Specification.new do |spec|
  # For explanations see http://docs.rubygems.org/read/chapter/20
  spec.name          = "barzahlen_v2"
  spec.version       = BarzahlenV2::VERSION
  spec.authors       = ["David Leib"]
  spec.email         = ["david.leib@barzahlen.de"]
  spec.description   = %q{This is a ruby gem to access the barzahlen api online v2 for online shops.}
  spec.summary       = %q{Client gem for api online v2}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake",                    "~> 10.4.1"
  spec.add_development_dependency "rspec",                   "~> 3.2.0"
  spec.add_development_dependency "builder",                 "~> 3.2.2" # Needed for ci-reporter
  spec.add_development_dependency "rspec_junit_formatter",   "~> 0.2.2"
  spec.add_development_dependency "rack-test",               "~> 0.6.3"

  spec.add_runtime_dependency "grac",                        "~> 2.2.0"
  spec.add_runtime_dependency "openssl",                     "~> 1.1.0"
end
