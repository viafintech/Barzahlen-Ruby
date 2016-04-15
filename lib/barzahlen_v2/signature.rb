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
        request_idempotency_key = opts[:headers]["Idempotency-Key"]
        # Prepare the Date header
        request_date_header = DateTime.new.strftime("%a, %d %b %Y %H:%M:%S %Z")

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          request_host_header,
          request_method,
          BarzahlenV2::configuration.payment_key,
          request_date_header,
          request_host_path,
          request_query_string,
          body,
          request_idempotency_key
          )

        # Attach the Date, Authorization and Host to the request
        signature_headers = {
            headers: {
              Date: request_date_header,
              Authorization: "BZ1-HMAC-SHA256 DivisionId=#{BarzahlenV2.configuration.division_id}, Signature=#{signature}",
              Host: request_host_header,
            }
          }

        result = @request.call(opts[:headers].merge(signature_headers), request_uri, method, params, body)

        return result
      end
    end

    def self.generate_bz_signature(request_host_header, request_method, payment_key, request_date_header,
      request_host_path = "", request_query_string = "", request_body = "", request_idempotency_key = "")
      request_body_digest = BarzahlenV2::Middleware.generate_sha256_digest(request_body)

      raw_signature = "#{request_host_header}\n#{request_method}\n#{request_host_path}\n#{request_query_string}\n"\
        "#{request_date_header}\n#{request_idempotency_key}\n#{request_body_digest}"

      OpenSSL::HMAC.hexdigest("SHA256", payment_key, raw_signature)
    end

    def self.generate_sha256_digest(string_to_hash)
      request_body_digest = OpenSSL::Digest.digest("SHA256", string_to_hash.to_s)
    end
  end
end
