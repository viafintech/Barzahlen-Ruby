# frozen_string_literal: true

module Barzahlen
  class Configuration
    API_HOST = 'https://api.barzahlen.de/v2'
    API_HOST_SANDBOX = 'https://api-sandbox.barzahlen.de/v2'

    attr_accessor :sandbox, :division_id, :payment_key

    def initialize
      @sandbox = false
      @division_id = 'not_valid_division_id'
      @payment_key = 'not_valid_payment_key'
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
