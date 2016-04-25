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
      BarzahlenV2.execute_with_error_handling do
        @request.path("/slips").post(@request_hash)
      end
    end
  end

  #If idempotency is not important a simple request is more than enough

  def self.retrieve_slip(slip_id)
    self.execute_with_error_handling do
      self.get_grac_client.path("/slips/{id}", id: slip_id.to_s).get
    end
  end

  def self.update_slip(slip_id, opts = {})
    self.execute_with_error_handling do
      self.get_grac_client.path("/slips/{id}", id: slip_id.to_s).patch(opts)
    end
  end

  def self.resend_email(slip_id)
    self.execute_with_error_handling do
      self.get_grac_client.path("/slips/{id}/resend/email", id: slip_id.to_s).post
    end
  end

  def self.resend_text_message(slip_id)
    self.execute_with_error_handling do
      self.get_grac_client.path("/slips/{id}/resend/text_message", id: slip_id.to_s).post
    end
  end

  def self.invalidate_slip(slip_id)
    self.execute_with_error_handling do
      self.get_grac_client.path("/slips/{id}/invalidate", id: slip_id.to_s).post
    end
  end

  # Handle a webhook request

  def self.webhook_request(request)
    bz_hook_format = request["Bz-Hook-Format"]

    #stop processing when bz-hook-format = v1 because it will be send as v2 again
    if bz_hook_format.include? "v1"
      return nil
    end

    signature = BarzahlenV2::Middleware.generate_bz_signature(
      BarzahlenV2.configuration.payment_key,
      request["Host"] + ":" + (request["Port"] || "443"),
      request["Method"] ? request["Method"].upcase : "POST",
      request["Date"],
      request["Path"].split("?")[0] || request["Path"],
      request["Path"].split("?")[1] || "",
      request["Body"]
    )

    if request["Bz-Signature"].include? signature
      return JSON.parse(request["Body"])
    else
      raise BarzahlenV2::Error::SignatureError.new("Signature not valid")
    end
  end

  private
    @@grac_client = nil

    def self.get_grac_client(idempotency = false)
      @@grac_client ||= Grac::Client.new(
          BarzahlenV2.configuration.sandbox ?
            BarzahlenV2::Configuration::API_HOST_SANDBOX : BarzahlenV2::Configuration::API_HOST,
          middleware: [ [ BarzahlenV2::Middleware::Signature, BarzahlenV2.configuration ] ]
          )

      if idempotency
        return @@grac_client.set( headers: { "Idempotency-Key" => SecureRandom.uuid} )
      else
        return @@grac_client
      end
    end

    def self.execute_with_error_handling
      begin
        yield
      rescue Grac::Exception::RequestFailed => e
        raise BarzahlenV2::Error.generate_error_from_response("")
      rescue  Grac::Exception::ClientException => e
        raise BarzahlenV2::Error.generate_error_from_response(e.body)
      end
    end
end
