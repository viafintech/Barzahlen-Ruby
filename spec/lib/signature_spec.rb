require "spec_helper"

module BarzahlenV2
  module Middleware
    describe Signature do
      it "generates the signature correctly" do
        date = "13 Apr 2016 15:00:00 GMT"
        request_uri = "https://api.barzahlen.de/v2"
        request_method = "get"
        date_dummy = double("Dummy Date")
        expect(date_dummy).to receive(:strftime).and_return(date)
        expect(DateTime).to receive(:new).and_return(date_dummy)
        request = double("Dummy Request")
        expect(request).to receive(:call).with(
          {
            headers: {
              Date: date,
              Authorization: "BZ1-HMAC-SHA256 DivisionId=123456, Signature=7ce8e51b81f05fb9eaaa97f47fce8f14fe1809946255e867d1c09013485af13d",
              Host: "api.barzahlen.de"
            }
          },
          request_uri,
          request_method,
          {},
          ""
          )

        BarzahlenV2.configure do |config|
          config.payment_key = "12345"
          config.division_id = "123456"
        end

        signature = Signature.new(request)
        signature.call({ headers: {}},request_uri,request_method,{},"")
      end
    end
  end
end