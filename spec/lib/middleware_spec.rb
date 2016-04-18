require "spec_helper"

module BarzahlenV2
  module Middleware
    describe Signature do
      before :each do
        BarzahlenV2.configure do |config|
          config.payment_key = "12345"
          config.division_id = "123456"
        end

        @date = "13 Apr 2016 15:00:00 GMT"
        @request_uri = "https://api.barzahlen.de/v2"
        @request_method = "get"
      end

      it "generates the signature correctly" do
        date_dummy = double("Dummy Date")
        expect(date_dummy).to receive(:strftime).and_return(@date)
        expect(DateTime).to receive(:new).and_return(date_dummy)
        response = double("Dummy Response")
        expect(response).to receive(:code).and_return("200")

        request = double("Dummy Request")

        expect(request).to receive(:call).with(
          {
            headers: {
              Date: @date,
              Authorization: "BZ1-HMAC-SHA256 DivisionId=123456, Signature=7ce8e51b81f05fb9eaaa97f47fce8f14fe1809946255e867d1c09013485af13d",
              Host: "api.barzahlen.de"
            }
          },
          @request_uri,
          @request_method,
          {},
          ""
          ).and_return(response)

        signature = Signature.new(request)
        signature.call({ headers: {}},@request_uri,@request_method,{},"")
      end

      it "raises exception if 400 is returned" do
        date_dummy = double("Dummy Date")
        expect(date_dummy).to receive(:strftime).and_return(@date)
        expect(DateTime).to receive(:new).and_return(date_dummy)
        response = double("Dummy Response")
        expect(response).to receive(:code).and_return("401").twice
        expect(response).to receive(:body).and_return("oops")

        request = double("Dummy Request")

        expect(request).to receive(:call).and_return(response)

        signature = Signature.new(request)
        expect{
            signature.call({ headers: {}},@request_uri,@request_method,{},"")
          }.to raise_error { |error|
            expect(error).to be_an(BarzahlenV2::Error::ApiError)
          }
      end
    end

    describe "Signature generation" do
      before :each do
        BarzahlenV2.configure do |config|
          config.division_id = "12345"
          config.payment_key = "123456"
        end

        @request_host_header = "api.barzahlen.de"
        @request_method = "GET"
        @request_date_header = "13 Apr 2016 15:00:00 GMT"
        @request_host_path = ""
        @request_query_string = ""
        @request_body = ""
        @request_idempotency_key = "61d2ee3d-bef3-4ab0-b81f-caf6e007f833"
      end

      it "generates the signature correctly with minimal setup" do
        signature = BarzahlenV2::Middleware.generate_bz_signature(
          @request_host_header,
          @request_method,
          @request_date_header
          )

        expect(signature).to eq("354dc8aad7823e9c13f1a35a19ee4f1f091cd73c517b0ebd3e6427e8b7d12ce5")
      end

      it "generates the signature correctly with idempotency key" do
        signature = BarzahlenV2::Middleware.generate_bz_signature(
          @request_host_header,
          @request_method,
          @request_date_header,
          @request_host_path,
          @request_query_string,
          @request_body,
          @request_idempotency_key
          )

        expect(signature).to eq("bd5b0ca2ab55759ddeebc778c03aa1ecaee5b91ed4de1a38ffb1f5af68a0137b")
      end

      it "generates the signature correctly everything set" do
        @request_host_path = "/v2"
        @request_query_string = "count=2"
        @request_body = "{\"foo\": \"bar\"}"

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          @request_host_header,
          @request_method,
          @request_date_header,
          @request_host_path,
          @request_query_string,
          @request_body,
          @request_idempotency_key
          )

        expect(signature).to eq("a5c597bdf1228d1da54b6cf711f04f5a09f90d0e48b88379f77596ffd45de7a2")
      end
    end
  end
end
