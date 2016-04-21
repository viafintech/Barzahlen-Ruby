require "openssl"
require "uri"
require "time"

module BarzahlenV2
  module Middleware
    class Signature
      def initialize(request, *settings)
        @request = request
        @settings = settings
      end

      def call (opts, request_uri, method, params, body)
        parsed_uri = URI.parse(request_uri)
        request_host_header = parsed_uri.host
        request_method = method
        request_host_path = parsed_uri.path
        request_query_string = URI.encode_www_form(params)
        request_idempotency_key = opts[:headers]["Idempotency-Key"]
        # Prepare the Date header
        request_date_header = Time.now.strftime("%a, %d %b %Y %H:%M:%S %Z")

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          request_host_header + ":" + parsed_uri.port.to_s,
          request_method,
          request_date_header,
          request_host_path,
          request_query_string,
          body,
          request_idempotency_key
          )

        # Attach the Date, Authorization and Host to the request
        new_headers =  opts[:headers].merge({
              Date: request_date_header,
              Authorization: "BZ1-HMAC-SHA256 DivisionId=#{BarzahlenV2.configuration.division_id}, Signature=#{signature}",
              Host: request_host_header,
            })

        begin
          result = @request.call({headers: new_headers}, request_uri, method, params, body)
        rescue Grac::Exception::RequestFailed => e
          raise BarzahlenV2::Error.generate_error_from_response(0,"")
        rescue Grac::Exception::BadRequest => e
          raise BarzahlenV2::Error.generate_error_from_response(400,e.body)
        rescue Grac::Exception::Forbidden => e
          raise BarzahlenV2::Error.generate_error_from_response(403,e.body)
        rescue Grac::Exception::NotFound => e
          raise BarzahlenV2::Error.generate_error_from_response(404,e.body)
        rescue Grac::Exception::Conflict => e
          raise BarzahlenV2::Error.generate_error_from_response(409,e.body)
        rescue Grac::Exception::ServiceError => e
          raise BarzahlenV2::Error.generate_error_from_response("Was not returned by Grac",e.body)
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

    def self.generate_bz_signature(
      request_host_header,
      request_method,
      request_date_header,
      request_host_path = "",
      request_query_string = "",
      request_body = "",
      request_idempotency_key = "")
      request_body_digest = OpenSSL::Digest.hexdigest("SHA256", request_body)

      raw_signature = "#{request_host_header}\n#{request_method.upcase}\n#{request_host_path}\n"\
      "#{request_query_string}\n#{request_date_header}\n#{request_idempotency_key}\n#{request_body_digest}"

      OpenSSL::HMAC.hexdigest("SHA256", BarzahlenV2::configuration.payment_key, raw_signature)
    end
  end
end
