require "json"

module BarzahlenV2
  module Error
    class ApiError
      attr_reader :http_status
      attr_reader :error_class
      attr_reader :error_code
      attr_reader :message
      attr_reader :documentation_url
      attr_reader :request_id

      def initialize(http_status,error_class,error_code,message,documentation_url,request_id)
        @http_status = http_status
        @error_class = error_class
        @error_code = error_code
        @message = message
        @documentation_url = documentation_url
        @request_id = request_id
      end

      def self.to_s
        return "Error occured with: #{@message}"\
               "Http Status Code: #{@http_status} "\
               "Barzahlen Error Code: #{@error_code} "\
               "Please look for help on: #{@documentation_url}"\
               "Your request_id is: #{@request_id}"
      end
    end

    def self.generate_error_from_response(http_status,response_json)
      parsed_json_error = JSON.parse(response_json)

      error_class_name = parsed_json_error["error_class"].capitalize

      begin
        BarzahlenV2::Error.const_get(error_class_name)
      rescue NameError
        error_class = Class.new(ApiError)
        BarzahlenV2::Error.const_set error_class_name, error_class
      end

      BarzahlenV2::Error.const_get(error_class_name).new(
        http_status,
        parsed_json_error["error_class"],
        parsed_json_error["error_code"],
        parsed_json_error["message"],
        parsed_json_error["documentation_url"],
        parsed_json_error["request_id"]
        )
    end
  end
end
