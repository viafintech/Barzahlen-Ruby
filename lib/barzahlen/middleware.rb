# frozen_string_literal: true

require 'openssl'
require 'uri'
require 'time'

module Barzahlen
  module Middleware
    class Signature
      def initialize(request, config)
        @request  = request
        @config   = config
      end

      def call(opts, request_uri, method, params, body)
        parsed_uri              = URI.parse(request_uri)
        request_host_header     = "#{parsed_uri.host}:#{parsed_uri.port}"
        request_method          = method
        request_host_path       = parsed_uri.path
        request_query_string    = URI.encode_www_form(params)
        request_idempotency_key = opts[:headers]['Idempotency-Key']
        request_date_header     = Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S GMT')

        signature = Barzahlen::Middleware.generate_bz_signature(
          @config.payment_key,
          request_host_header,
          request_method,
          request_date_header,
          request_host_path,
          request_query_string,
          body,
          request_idempotency_key
        )

        # Attach the Date, Authorization and Host to the request
        new_headers = opts[:headers].merge(
          {
            Date: request_date_header,
            Authorization: "BZ1-HMAC-SHA256 DivisionId=#{@config.division_id}, Signature=#{signature}",
            Host: request_host_header
          }
        )

        return @request.call({ headers: new_headers }, request_uri, method, params, body)
      end
    end

    def self.generate_bz_signature(
      payment_key,
      request_host_header,
      request_method,
      request_date_header,
      request_host_path = '',
      request_query_string = '',
      request_body = '',
      request_idempotency_key = ''
    )

      request_body_digest = OpenSSL::Digest.hexdigest('SHA256', request_body.to_s || '')

      raw_signature = "#{request_host_header}\n"\
                      "#{request_method.upcase}\n"\
                      "#{request_host_path}\n"\
                      "#{request_query_string}\n"\
                      "#{request_date_header}\n"\
                      "#{request_idempotency_key}\n"\
                      "#{request_body_digest}"

      OpenSSL::HMAC.hexdigest('SHA256', payment_key, raw_signature)
    end
  end
end
