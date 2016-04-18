require "spec_helper"

module BarzahlenV2
  module Online
    describe Slip do
      let(:refund_slip) {
        return {
            slip_type: "refund",
            refund: {
              for_slip_id: "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd"
            },
            transactions: [
              {
                currency: "EUR",
                amount: "-23.99"
              }
            ]
          }
      }

      let(:payment_slip) {
        return {
            slip_type: "payment",
            customer: {
              key: "ASDFJKL"
            },
            transactions: [
              {
                currency: "EUR",
                amount: "321.47"
              }
            ]
          }
      }

      before :each do
        @@grac_client = nil
      end

      it "generates a refund with idempotency header" do
        request_client = double("Dummy Request Client")
        expect(request_client).to receive(:set)
        expect(Grac::Client).to receive(:new).and_return(request_client)
        expect {
          BarzahlenV2::Online::Slip.new(refund_slip)
          }.to_not raise_error
      end

      it "generates a payment with idempotency header" do
        request_client = double("Dummy Request Client")
        expect(request_client).to receive(:set)
        expect(Grac::Client).to receive(:new).and_return(request_client)
        expect {
          BarzahlenV2::Online::Slip.new(payment_slip)
          }.to_not raise_error
      end

      it "payment fails if no slip type is specified" do
        payment_slip.delete(:slip_type)
        expect {
            BarzahlenV2::Online::Slip.new(payment_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_type'")
          }
      end

      it "payment fails if no customer is specified" do
        payment_slip.delete(:customer)
        expect {
            BarzahlenV2::Online::Slip.new(payment_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'customer > key','transactions > amount','transactions > currency'")
          }
      end

      it "payment fails if no transaction is specified" do
        payment_slip.delete(:transactions)
        expect {
            BarzahlenV2::Online::Slip.new(payment_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'customer > key','transactions > amount','transactions > currency'")
          }
      end

      it "refund fails if no slip_type is specified" do
        refund_slip.delete(:slip_type)
        expect {
            BarzahlenV2::Online::Slip.new(refund_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_type'")
          }
      end

      it "refund fails if no refund is specified" do
        refund_slip.delete(:refund)
        expect {
            BarzahlenV2::Online::Slip.new(refund_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'for_slip_id','transactions > amount','transactions > currency'")
          }
      end

      it "refund fails if no transaction is specified" do
        refund_slip.delete(:transactions)
        expect {
            BarzahlenV2::Online::Slip.new(refund_slip)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'for_slip_id','transactions > amount','transactions > currency'")
          }
      end

      it "is setting correct uri" do
        request = BarzahlenV2::Online::Slip.new(refund_slip)

        expect(@@grac_client.uri).to eq("https://api.barzahlen.de/v2")
      end

      it "is setting correct sandbox uri" do
        BarzahlenV2.configure { |config|
          config.sandbox = true
        }

        request = BarzahlenV2::Online::Slip.new(refund_slip)

        expect(@@grac_client.uri).to eq("https://api-sandbox.barzahlen.de/v2")
      end

      it "generates a payment and creates request with grac" do
        request_client = double("Dummy Request Client")
        request_client_with_idempotency = double("Dummy Idempotency Request Client")
        expect(request_client_with_idempotency).to receive(:path).and_return(request_client_with_idempotency)
        expect(request_client_with_idempotency).to receive(:post).with(payment_slip)
        expect(request_client).to receive(:set).and_return(request_client_with_idempotency)
        expect(Grac::Client).to receive(:new).and_return(request_client)
        new_payment_slip = nil
        expect {
          new_payment_slip = BarzahlenV2::Online::Slip.new(payment_slip)
          }.to_not raise_error
        expect {
          new_payment_slip.create
          }.to_not raise_error
      end
    end

    describe "Retrieving a slip" do
      it "does not accept nil slip_id" do
        expect {
            BarzahlenV2::Online.retrieve_slip(nil)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_id'")
          }
      end
    end

    describe "Updating a slip" do
      it "does not accept nil slip_id" do
        expect {
            BarzahlenV2::Online.update_slip(nil,{})
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_id'")
          }
      end
    end

    describe "Resend a slip" do
      it "does not accept nil slip_id" do
        expect {
            BarzahlenV2::Online.resend_slip(nil,"email")
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_id','message_type'")
          }
      end

      it "does not accept nil message_type" do
        expect {
            BarzahlenV2::Online.resend_slip(nil,"email")
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_id','message_type'")
          }
      end
    end

    describe "Invalidate a slip" do
      it "does not accept nil slip_id" do
        expect {
            BarzahlenV2::Online.invalidate_slip(nil)
          }.to raise_error { |error|
            expect(error.message).to eq("One or all MissingArgument(s): 'slip_id'")
          }
      end
    end

    describe "Webhook request" do
      #need to test
    end
  end
end
