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
              Authorization: "BZ1-HMAC-SHA256 DivisionId=123456, Signature=8c2cfde1cfb24289a5534a8af5e4d90082c54ace7461419da483b01cd4efb519",
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

        expect(signature).to eq("f9657db3b4adba7c838a16f22a7e3202c80d5f09c2a8caae7f065d0015b6c0b1")
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

        expect(signature).to eq("6152ebdf8ba4254bf069c63c7e84d48a8f85606821a17637ecf838114a7b3159")
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

        expect(signature).to eq("35235b5aa4a7a0e30aa6ca9fe115cfff2f8b100ddca0eaf8370f2c557305a1f8")
      end

      it "generates a correct webhook signature" do
        BarzahlenV2.configure do |config|
          config.payment_key = "6b3fb3abef828c7d10b5a905a49c988105621395"
        end

        @request_host_header = "callback.example.com"
        @request_method = "POST"
        @request_date_header = "Fri, 01 Apr 2016 09:20:06 GMT"
        @request_host_path = "/barzahlen/callback"
        @request_query_string = ""
        @request_body = {
            "event" => "paid",
            "event_occurred_at" => "2016-01-06T12:34:56Z",
            "affected_transaction_id" => "4729294329",
            "slip" => {
                "id" => "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
                "slip_type" => "payment",
                "division_id" => "1234",
                "reference_key" => "O64737X",
                "expires_at" => "2016-01-10T12:34:56Z",
                "customer" => {
                    "key" => "LDFKHSLFDHFL",
                    "cell_phone_last_4_digits" => "6789",
                    "email" => "john@example.com",
                    "language" => "de-DE"
                },
                "metadata" => {
                  "order_id" => 1234,
                  "invoice_no" => "A123"
                },
                "transactions" => [
                  {
                    "id" => "4729294329",
                    "currency" => "EUR",
                    "amount" => "123.34",
                    "state" => "paid"
                  }
                ]
            }
        }.to_json
        @request_idempotency_key = ""

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          @request_host_header,
          @request_method,
          @request_date_header,
          @request_host_path,
          @request_query_string,
          @request_body,
          @request_idempotency_key
          )

        expect(signature).to eq("eb22cda264a5cf5a138e8ac13f0aa8da2daf28c687d9db46872cf777f0decc04")
      end

      it "generates the signature correctly everything set" do
        BarzahlenV2.configure do |config|
          config.payment_key = "6b3fb3abef828c7d10b5a905a49c988105621395"
        end

        @request_host_header = "api.barzahlen.de"
        @request_method = "GET"
        @request_date_header = "Thu, 31 Mar 2016 10:50:31 GMT"
        @request_host_path = "/v2/slips/slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd"
        @request_query_string = ""
        @request_body = ""
        @request_idempotency_key = ""

        signature = BarzahlenV2::Middleware.generate_bz_signature(
          @request_host_header,
          @request_method,
          @request_date_header,
          @request_host_path,
          @request_query_string,
          @request_body,
          @request_idempotency_key
          )

        expect(signature).to eq("3b1a28fffd1cd2bbc1ec24cfbca1e85d802159e78c08328d92d4337a4a33b61d")
      end
    end
  end
end
