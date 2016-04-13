require "spec_helper"

module BarzahlenV2
  module Error
    describe "Api Error" do
      it "it can generate classes" do
        json_error_response = "{ \"error_class\": \"invalid_parameter\","\
          "\"error_code\": \"reference_key_already_exists\","\
          "\"message\": \"The given reference key already exists - use another one.\","\
          "\"request_id\": \"64ec26b27d414a66b87f2ec7cad7e92c\" }"
        error_class = BarzahlenV2::Error.generate_error_from_response("400",json_error_response)
        expect(error_class.class.name).to eq("BarzahlenV2::Error::Invalid_parameter")
        expect(error_class.error_code).to eq("reference_key_already_exists")
      end
    end
  end
end