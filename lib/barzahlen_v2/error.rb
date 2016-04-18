require "json"

module BarzahlenV2
  module Error
    class ArgumentMissing < StandardError
      attr_reader :argument

      def initialize(argument = [])
        @argument = argument
      end

      def message
        return "One or all MissingArgument(s): '#{argument.join("','")}'"
      end

      alias_method :to_s, :message
    end

    class SignatureError < StandardError
      attr_reader :error_message

      def initialize(error_message)
        @error_message = error_message
      end

      def message
        return @error_message
      end

      alias_method :to_s, :message
    end

    class ApiError < StandardError
      attr_reader :http_status, :error_class, :error_code, :error_message, :documentation_url, :request_id

      def initialize(http_status, error_class, error_code, message, documentation_url, request_id)
        @http_status = http_status.to_s
        @error_class = error_class
        @error_code = error_code
        @error_message = message
        @documentation_url = documentation_url
        @request_id = request_id
      end

      def message
        return "Error occured with: #{@error_message} "\
               "Http Status Code: #{@http_status} "\
               "Barzahlen Error Code: #{@error_code} "\
               "Please look for help on: #{@documentation_url} "\
               "Your request_id is: #{@request_id}"
      end

      alias_method :to_s, :message
    end

    # This generates ApiErrors based on the response error classes of CPS
    def self.generate_error_from_response(http_status, response_body)
      error_hash = generate_error_hash_with_symbols(response_body)

      error_class_name = error_hash[:error_class].capitalize.tr(" ","_")

      begin
        BarzahlenV2::Error.const_get(error_class_name)
      rescue NameError
        error_class = Class.new(ApiError)
        BarzahlenV2::Error.const_set error_class_name, error_class
      end

      BarzahlenV2::Error.const_get(error_class_name).new(
        http_status,
        error_hash[:error_class],
        error_hash[:error_code],
        error_hash[:message],
        error_hash[:documentation_url],
        error_hash[:request_id]
        )
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

        error_hash[:error_class] ||= "Unexpected_Error"
        error_hash[:error_code] ||= "Unknown error code (body): \"#{body.to_s}\""
        error_hash[:message] ||= "Please contact CPS to help us fix that as soon as possible."
        error_hash[:documentation_url] ||= "https://www.cashpaymentsolutions.com/de/geschaeftskunden/kontakt"
        error_hash[:request_id] ||= "not_available"

        error_hash
      end

      def self.symbolize_keys(hash)
        Hash[hash.map{ |k, v| [k.to_sym, v] }]
      end
  end
end
