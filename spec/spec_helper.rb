# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'test'

require 'rack/test'
require './lib/barzahlen'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  config.include Rack::Test::Methods
end
