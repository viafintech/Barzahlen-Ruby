require "openssl"
require "uri"
require "date"

module BarzahlenV2
  module Middleware
    class Signature
      def initialize(request, *settings)
        @request = request
        @settings = settings
      end

      def call (opts, request_uri, method, params, body)
        request_host_header = URI.parse(request_uri).host
        request_method = method
        request_host_path = URI.parse(request_uri).path
        request_query_string = URI.encode_www_form(params)
        request_idempotency_key = opts[:headers]["Idempotency-Key"]
        # Prepare the Date header
        request_date_header = DateTime.new.strftime("%a, %d %b %Y %H:%M:%S %Z")

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          request_host_header,
          request_method,
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

        begin
          result = @request.call(opts[:headers].merge(signature_headers), request_uri, method, params, body)
        rescue Grac::Exception::BadRequest,
               Grac::Exception::Forbidden,
               Grac::Exception::NotFound,
               Grac::Exception::Conflict
          # check_bz_response_for_failure will take care of the error creation
        end

        check_bz_response_for_failure(result)

        return result
      end

      def check_bz_response_for_failure(response)
        if [*400..599].include? response.code.to_i
          raise BarzahlenV2::Error.generate_error_from_response(response.code,response.body)
        end
      end
    end

    def self.generate_bz_signature(request_host_header, request_method, request_date_header,
      request_host_path = "", request_query_string = "", request_body = "", request_idempotency_key = "")
      request_body_digest = self.generate_sha256_digest(request_body)

      raw_signature = "#{request_host_header}\n#{request_method.upcase}\n#{request_host_path}\n#{request_query_string}\n"\
        "#{request_date_header}\n#{request_idempotency_key}\n#{request_body_digest}"

      OpenSSL::HMAC.hexdigest("SHA256", BarzahlenV2::configuration.payment_key, raw_signature)
    end

    def self.generate_sha256_digest(string_to_hash)
      request_body_digest = OpenSSL::Digest.digest("SHA256", string_to_hash.to_s)
    end
  end
end
