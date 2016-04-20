require "securerandom"
require "uri"
require "json"

module BarzahlenV2
  IDEMPOTENCY_ENABLED = true

  #For idempotency purposes a class takes care of refund and payment

  class Slip
    def initialize(opts = {})
      @request = BarzahlenV2.get_grac_client(BarzahlenV2::IDEMPOTENCY_ENABLED)
      @request_hash = opts
    end

    def create
      @request_hash.freeze
      @request_hash.each do |key, value|
        @request_hash[key].freeze
      end
      @request.path("/slips").post(@request_hash)
    end
  end

  #If idempotency is not important a simple request is more than enough

  def self.retrieve_slip(slip_id)
    self.get_grac_client.path("/slips/{id}", id: slip_id.to_s).get
  end

  def self.update_slip(slip_id, opts = {})
    self.get_grac_client.path("/slips/{id}", id: slip_id.to_s).patch(opts)
  end

  def self.resend_email(slip_id)
    self.get_grac_client.path("/slips/{id}/resend/email", id: slip_id.to_s).post
  end

  def self.resend_text_message(slip_id)
    self.get_grac_client.path("/slips/{id}/resend/text_message", id: slip_id.to_s).post
  end

  def self.invalidate_slip(slip_id)
    self.get_grac_client.path("/slips/{id}/invalidate", id: slip_id.to_s).post
  end

  private
    @@grac_client = nil

    def self.get_grac_client(idempotency = false)
      if !@@grac_client
        @@grac_client = Grac::Client.new(
          BarzahlenV2.configuration.sandbox ? BarzahlenV2::Configuration::API_HOST_SANDBOX :
            BarzahlenV2::Configuration::API_HOST,
          middleware: [BarzahlenV2::Middleware::Signature]
          )
      end

      if idempotency
        return @@grac_client.set( headers: { "Idempotency-Key" => SecureRandom.uuid} )
      else
        return @@grac_client
      end
    end
end
