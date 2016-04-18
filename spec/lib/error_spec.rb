require "spec_helper"
require "json"

module BarzahlenV2
  module Error
    describe ArgumentMissing do
      it "should be of type StandardError" do
        exception = BarzahlenV2::Error::ArgumentMissing.new(["slip_id"])

        expect(exception).to be_an(StandardError)
      end

      it "creates error message correctly" do
        exception = BarzahlenV2::Error::ArgumentMissing.new(["slip_id"])

        expect(exception.message).to eq("One or all MissingArgument(s): 'slip_id'")
        expect(exception.message).to eq("One or all MissingArgument(s): 'slip_id'")
      end

      it "creates multiple values error message correctly" do
        exception = BarzahlenV2::Error::ArgumentMissing.new(["slip_id","customer_key"])

        expect(exception.message).to eq("One or all MissingArgument(s): 'slip_id','customer_key'")
      end
    end

    describe ApiError do
      before do
        @response = {
          error_class: "invalid_parameter",
          error_code: "reference_key_already_exists",
          message: "The given reference key already exists - use another one.",
          documentation_url: "https://www.barzahlen.de/",
          request_id: "64ec26b27d414a66b87f2ec7cad7e92c"
        }
      end

      it "should be of type StandardError" do
        error_class = BarzahlenV2::Error.generate_error_from_response("400", @response.to_json)

        expect(error_class).to be_an(StandardError)
      end

      it "generate invalid_parameter class from json" do
        error_class = BarzahlenV2::Error.generate_error_from_response("400", @response.to_json)
        expect(error_class.class.name).to eq("BarzahlenV2::Error::Invalid_parameter")
      end

      it "generate invalid_parameter class from hash with strings" do
        string_hash = Hash[@response.map { |k, v| [k.to_s,v]}]
        error_class = BarzahlenV2::Error.generate_error_from_response("400", string_hash)
        expect(error_class.class.name).to eq("BarzahlenV2::Error::Invalid_parameter")
      end

      it "generate invalid_parameter class from hash with symbols" do
        error_class = BarzahlenV2::Error.generate_error_from_response("400", @response)
        expect(error_class.class.name).to eq("BarzahlenV2::Error::Invalid_parameter")
      end

      it "generates valid error messages" do
        error_class = BarzahlenV2::Error.generate_error_from_response("502", @response)

        expect(error_class.message).to eq("Error occured with: The given reference key already exists - use another one. "\
               "Http Status Code: 502 "\
               "Barzahlen Error Code: reference_key_already_exists "\
               "Please look for help on: https://www.barzahlen.de/ "\
               "Your request_id is: 64ec26b27d414a66b87f2ec7cad7e92c")
      end

      it "set error values" do
        error_class = BarzahlenV2::Error.generate_error_from_response("400", @response)

        expect(error_class.http_status).to eq("400")
        expect(error_class.error_class).to eq("invalid_parameter")
        expect(error_class.error_code).to eq("reference_key_already_exists")
        expect(error_class.error_message).to eq("The given reference key already exists - use another one.")
        expect(error_class.documentation_url).to eq("https://www.barzahlen.de/")
        expect(error_class.request_id).to eq("64ec26b27d414a66b87f2ec7cad7e92c")
      end

      it "has immutable values" do
        error_class = BarzahlenV2::Error.generate_error_from_response("400", @response)

        expect{error_class.http_status = 1}.to raise_error(NoMethodError)
        expect{error_class.error_class = 1}.to raise_error(NoMethodError)
        expect{error_class.error_code = 1}.to raise_error(NoMethodError)
        expect{error_class.error_message = 1}.to raise_error(NoMethodError)
        expect{error_class.documentation_url = 1}.to raise_error(NoMethodError)
        expect{error_class.request_id = 1}.to raise_error(NoMethodError)
      end

      it "generate default error message when supplying simple string" do
        error_body = "502 Bad Gateway"
        error_class = BarzahlenV2::Error.generate_error_from_response(502, error_body)

        expect(error_class.message).to eq("Error occured with: Please contact CPS to help us fix that as soon as possible. "\
               "Http Status Code: 502 "\
               "Barzahlen Error Code: Unknown error code (body): \"502 Bad Gateway\" "\
               "Please look for help on: https://www.cashpaymentsolutions.com/de/geschaeftskunden/kontakt "\
               "Your request_id is: not_available")
      end
    end
  end
end