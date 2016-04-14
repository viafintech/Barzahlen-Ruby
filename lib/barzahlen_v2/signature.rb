require "openssl"
require "uri"

module BarzahlenV2
  module Middleware
    class Signature
      def initialize(request, *settings)
        @request = request
        @settings = settings
      end

      def call (opts, request_uri, method, params, body)
        request_host_header = URI.parse(request_uri).host
        request_method = method.upcase
        request_host_path = URI.parse(request_uri).path
        request_query_string = URI.encode_www_form(params)
        request_idempotency_key = @settings[0] if @settings
        # Prepare the Date header
        request_date_header = DateTime.new.strftime("%a, %d %b %Y %H:%M:%S %Z")

        request_body_digest = OpenSSL::Digest.digest("SHA256", body.to_s)

        signature = "#{request_host_header}\n#{request_method}\n#{request_host_path}\n#{request_query_string}\n#{request_date_header}\n#{request_idempotency_key}\n#{request_body_digest}"

        signature = OpenSSL::HMAC.hexdigest("SHA256", BarzahlenV2.configuration.payment_key, signature)

        # Attach the Date, Authorization and Host to the request
        signature_headers = {
            headers: {
              Date: request_date_header,
              Authorization: "BZ1-HMAC-SHA256 DivisionId=#{BarzahlenV2.configuration.division_id}, Signature=#{signature}",
              Host: request_host_header,
            }
          }

        if request_idempotency_key
          signature_headers[:headers]["Idempotency-Key"] = request_idempotency_key
        end

        result = @request.call(opts[:headers].merge(signature_headers), request_uri, method, params, body)

        return result
      end
    end
  end
end
