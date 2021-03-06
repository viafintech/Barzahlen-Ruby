require "securerandom"
require "json"

module Barzahlen
  IDEMPOTENCY_ENABLED = true

  # For idempotency purposes a class takes care of refund and payment

  class CreateSlipRequest
    def initialize(opts = {})
      @request = Barzahlen.get_grac_client(Barzahlen::IDEMPOTENCY_ENABLED)
      @request_hash = opts
    end

    def send
      @request_hash.freeze
      @request_hash.each do |key, value|
        @request_hash[key].freeze
      end
      Barzahlen.execute_with_error_handling do
        @request.path("/slips").post(@request_hash)
      end
    end
  end

  # If idempotency is not important a simple request is more than enough

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

    #stop processing when bz-hook-format = v1 because it will be or was send as v2
    if bz_hook_format.include? "v1"
      return nil
    end

    signature = Barzahlen::Middleware.generate_bz_signature(
      Barzahlen.configuration.payment_key,
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
      raise Barzahlen::Error::SignatureError.new("Signature not valid")
    end
  end


  private

    @@grac_client = nil

    def self.get_grac_client(idempotency = false)
      @@grac_client ||= Grac::Client.new(
          Barzahlen.configuration.sandbox ?
            Barzahlen::Configuration::API_HOST_SANDBOX : Barzahlen::Configuration::API_HOST,
          middleware: [ [ Barzahlen::Middleware::Signature, Barzahlen.configuration ] ]
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
        raise Barzahlen::Error.generate_error_from_response("")
      rescue  Grac::Exception::ClientException => e
        raise Barzahlen::Error.generate_error_from_response(e.body)
      end
    end
end
