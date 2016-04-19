require "securerandom"
require "uri"
require "json"

module BarzahlenV2
  module Online
    IDEMPOTENCY_ENABLED = true

    #For idempotency purposes a class takes care of refund and payment

    class Slip
      def initialize(opts = {})
        if !opts[:slip_type]
          raise BarzahlenV2::Error::ArgumentMissing.new(["slip_type"])
        end

        if opts[:slip_type].eql? "refund"
          begin
            if !opts[:refund][:for_slip_id] || !opts[:transactions][0][:amount] || \
              !opts[:transactions][0][:currency]
              raise BarzahlenV2::Error::ArgumentMissing.new(["for_slip_id","transactions > amount",
                "transactions > currency"])
            end
          rescue NoMethodError
            raise BarzahlenV2::Error::ArgumentMissing.new(["for_slip_id","transactions > amount",
              "transactions > currency"])
          end
        elsif opts[:slip_type].eql? "payment"
          begin
            if !opts[:customer][:key] || !opts[:transactions][0][:amount] || \
              !opts[:transactions][0][:currency]
              raise BarzahlenV2::Error::ArgumentMissing.new(["customer > key","transactions > amount",
                                                             "transactions > currency"])
            end
          rescue NoMethodError
            raise BarzahlenV2::Error::ArgumentMissing.new(["customer > key","transactions > amount",
                                                           "transactions > currency"])
          end
        else
          raise BarzahlenV2::Error::ArgumentMissing.new(["slip_type"])
        end

        @request = BarzahlenV2::Online.get_grac_client(BarzahlenV2::Online::IDEMPOTENCY_ENABLED)
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
      if !slip_id
        raise BarzahlenV2::Error::ArgumentMissing.new(["slip_id"])
      end

      self.get_grac_client.path("/slips/#{slip_id}").get
    end

    def self.update_slip(slip_id, opts = {})
      if !slip_id
        raise BarzahlenV2::Error::ArgumentMissing.new(["slip_id"])
      end
      self.get_grac_client.path("/slips/#{slip_id}").patch(opts)
    end

    def self.resend_slip(slip_id, message_type)
      if !slip_id || !message_type
        raise BarzahlenV2::Error::ArgumentMissing.new(["slip_id","message_type"])
      end
      self.get_grac_client.path("/slips/#{opts[:id]}/resend/#{opts[:message_type]}").post
    end

    def self.invalidate_slip(slip_id)
      if !slip_id
        raise BarzahlenV2::Error::ArgumentMissing.new(["slip_id"])
      end
      self.get_grac_client.path("slips/#{slip_id}/invalidate")
    end

    # Handle a webhook request

    def self.webhook_request(response)
      bz_hook_format = response.headers["Bz-Hook-Format"]

      #stop processing when bz-hook-format = v1 because it will be send as v2 again
      if bz_hook_format.include? "v1"
        return nil
      end

      content_type = response.headers["Content-Type"]

      if ! content_type.include? "application/json"
        return nil
      end

      bz_signature = response.headers["Bz-Signature"]

      signature = BarzahlenV2::Middleware.generate_bz_signature(
        response.headers["Host"],
        "POST",
        response.headers["Date"],
        response.location,
        "",
        response.body
        )

      puts signature
      puts response.headers["Bz-Signature"]

      if bz_signature.include? signature
        return JSON.parse(response.body)
      else
        raise BarzahlenV2::Error::SignatureError.new("Signature not valid")
      end
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
end
