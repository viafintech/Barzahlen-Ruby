module BarzahlenV2
  Api_host = "https://api.barzahlen.de/"
  Api_host_sandbox = "https://api-sandbox.barzahlen.de/"

  class Configuration
    attr_accessor :sandbox
    attr_accessor :division_id
    attr_accessor :payment_key

    def initialize
      @sandbox = false
      @division_id = "not_valid_division_id"
      @payment_key = "not_valid_payment_key"
    end
  end
end
