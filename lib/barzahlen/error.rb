# frozen_string_literal: true

require 'json'

module Barzahlen
  module Error
    class ClientError < StandardError
      attr_reader :error_message

      def initialize(error_message)
        super
        @error_message = error_message
      end

      def message
        return @error_message
      end

      alias to_s message
    end

    class SignatureError < ClientError; end

    class ApiError < StandardError
      attr_reader :error_class, :error_code, :error_message, :documentation_url, :request_id

      def initialize(error_hash = {})
        super
        @error_class = error_hash[:error_class]
        @error_code = error_hash[:error_code]
        @error_message = error_hash[:message]
        @documentation_url = error_hash[:documentation_url]
        @request_id = error_hash[:request_id]
      end

      def message
        return "Error occurred with: #{@error_message}"
      end

      alias to_s message
    end

    class AuthError             < ApiError; end
    class TransportError        < ApiError; end
    class IdempotencyError      < ApiError; end
    class RateLimitError        < ApiError; end
    class InvalidFormatError    < ApiError; end
    class InvalidStateError     < ApiError; end
    class InvalidParameterError < ApiError; end
    class NotAllowedError       < ApiError; end
    class ServerError           < ApiError; end
    class UnexpectedError       < ApiError; end

    # This generates ApiErrors based on the response error classes of CPS
    def self.generate_error_from_response(response_body)
      error_hash = generate_error_hash_with_symbols(response_body)

      return {
        auth: AuthError.new(error_hash),
        transport: TransportError.new(error_hash),
        idempotency: IdempotencyError.new(error_hash),
        rate_limit: RateLimitError.new(error_hash),
        invalid_format: InvalidFormatError.new(error_hash),
        invalid_state: InvalidStateError.new(error_hash),
        invalid_parameter: InvalidParameterError.new(error_hash),
        not_allowed: NotAllowedError.new(error_hash),
        server_error: ServerError.new(error_hash)
      }[error_hash[:error_class].to_sym] || UnexpectedError.new(error_hash)
    end

    def self.parse_json(json)
      begin
        hash = JSON.parse(json)
      rescue JSON::ParserError
        return nil
      end
      symbolize_keys(hash)
    end

    def self.generate_error_hash_with_symbols(body)
      error_hash = case body
                   when Hash
                     symbolize_keys(body)
                   when String
                     parse_json(body) || {}
                   else
                     {}
                   end

      error_hash[:error_code] ||= "Unknown error code (body): \"#{body}\""

      error_hash_defaults.merge error_hash
    end

    def self.symbolize_keys(hash)
      Hash[hash.map { |k, v| [k.to_sym, v] }]
    end

    def self.error_hash_defaults
      {
        error_class: 'Unexpected_Error',
        message: 'Please contact CPS to help us fix that as soon as possible.',
        documentation_url: 'https://www.cashpaymentsolutions.com/de/geschaeftskunden/kontakt',
        request_id: 'not_available'
      }
    end
  end
end
