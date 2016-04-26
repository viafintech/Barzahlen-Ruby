require "json"

module Barzahlen
  module Error
    class ClientError < StandardError
      attr_reader :error_message

      def initialize(error_message)
        @error_message = error_message
      end

      def message
        return @error_message
      end

      alias_method :to_s, :message
    end

    class SignatureError < ClientError; end

    class ApiError < StandardError
      attr_reader :error_class
      attr_reader :error_code
      attr_reader :error_message
      attr_reader :documentation_url
      attr_reader :request_id

      def initialize(error_hash = {})
        @error_class = error_hash[:error_class]
        @error_code = error_hash[:error_code]
        @error_message = error_hash[:message]
        @documentation_url = error_hash[:documentation_url]
        @request_id = error_hash[:request_id]
      end

      def message
        return "Error occurred with: #{@error_message}"
      end

      alias_method :to_s, :message
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

      case error_hash[:error_class]
      when "auth"
        return AuthError.new( error_hash )
      when "transport"
        return TransportError.new( error_hash )
      when "idempotency"
        return IdempotencyError.new( error_hash )
      when "rate_limit"
        return RateLimitError.new( error_hash )
      when "invalid_format"
        return InvalidFormatError.new( error_hash )
      when "invalid_state"
        return InvalidStateError.new( error_hash )
      when "invalid_parameter"
        return InvalidParameterError.new( error_hash )
      when "not_allowed"
        return NotAllowedError.new( error_hash )
      when "server_error"
        return ServerError.new( error_hash )
      else
        return UnexpectedError.new( error_hash )
      end
    end


    private

      def self.parse_json(json)
        begin
          hash = JSON.parse(json)
        rescue JSON::ParserError => e
          return nil
        end
        self.symbolize_keys(hash)
      end

      def self.generate_error_hash_with_symbols(body)
        if body.is_a?(Hash)
          error_hash = self.symbolize_keys(body)
        elsif body.is_a?(String)
          error_hash = parse_json(body) || {}
        else
          error_hash = Hash.new
        end

        error_hash[:error_class]       ||= "Unexpected_Error"
        error_hash[:error_code]        ||= "Unknown error code (body): \"#{body.to_s}\""
        error_hash[:message]           ||= "Please contact CPS to help us fix that as soon as possible."
        error_hash[:documentation_url] ||= "https://www.cashpaymentsolutions.com/de/geschaeftskunden/kontakt"
        error_hash[:request_id]        ||= "not_available"

        error_hash
      end

      def self.symbolize_keys(hash)
        Hash[hash.map{ |k, v| [k.to_sym, v] }]
      end
  end
end
