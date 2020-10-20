# frozen_string_literal: true

require 'spec_helper'

module Barzahlen
  describe Configuration do
    it 'has valid default values' do
      config = Configuration.new
      expect(config.sandbox).to be(false)
      expect(config.division_id).to eq('not_valid_division_id')
      expect(config.payment_key).to eq('not_valid_payment_key')
    end

    it 'has valid constant values' do
      expect(Barzahlen::Configuration::API_HOST).to eq('https://api.barzahlen.de/v2')
      expect(Barzahlen::Configuration::API_HOST_SANDBOX).to eq('https://api-sandbox.barzahlen.de/v2')
    end

    it 'can set specific values' do
      config = Configuration.new
      config.sandbox = true
      config.division_id = '12345'
      config.payment_key = '12345'

      expect(config.sandbox).to be(true)
      expect(config.division_id).to eq('12345')
      expect(config.payment_key).to eq('12345')
    end
  end
end
