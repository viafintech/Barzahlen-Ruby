# frozen_string_literal: true

require 'spec_helper'
require 'json'

module Barzahlen
  describe CreateSlipRequest do
    let(:refund_slip) {
      return {
        slip_type: 'refund',
        refund: {
          for_slip_id: 'slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd'
        },
        transactions: [
          {
            currency: 'EUR',
            amount: '-23.99'
          }
        ]
      }
    }

    let(:payment_slip) {
      return {
        slip_type: 'payment',
        customer: {
          key: 'ASDFJKL'
        },
        transactions: [
          {
            currency: 'EUR',
            amount: '321.47'
          }
        ]
      }
    }

    before :each do
      @@grac_client = nil
    end

    it 'generates a refund with idempotency header' do
      request_client = double('Dummy Request Client')
      expect(request_client).to receive(:set).with(hash_including(headers: { 'Idempotency-Key' => // }))
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect {
        Barzahlen::CreateSlipRequest.new(refund_slip)
      }.to_not raise_error
    end

    it 'generates a payment with idempotency header' do
      request_client = double('Dummy Request Client')
      expect(request_client).to receive(:set).with(hash_including(headers: { 'Idempotency-Key' => // }))
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect {
        Barzahlen::CreateSlipRequest.new(payment_slip)
      }.to_not raise_error
    end

    it 'is setting correct uri' do
      Barzahlen::CreateSlipRequest.new(refund_slip)

      expect(@@grac_client.uri).to eq('https://api.barzahlen.de/v2')
    end

    it 'is setting correct sandbox uri' do
      Barzahlen.configure do |config|
        config.sandbox = true
      end

      Barzahlen::CreateSlipRequest.new(refund_slip)

      expect(@@grac_client.uri).to eq('https://api-sandbox.barzahlen.de/v2')
    end

    it 'generates a payment and creates request with grac' do
      request_client = double('Dummy Request Client')
      request_client_with_idempotency = double('Dummy Idempotency Request Client')

      expect(request_client).to receive(:set).with(hash_including(headers: { 'Idempotency-Key' => // })).and_return(request_client_with_idempotency)
      expect(request_client_with_idempotency).to receive(:path).and_return(request_client_with_idempotency)
      expect(request_client_with_idempotency).to receive(:post).with(payment_slip)

      expect(Grac::Client).to receive(:new).and_return(request_client)

      new_payment_slip = nil
      expect {
        new_payment_slip = Barzahlen::CreateSlipRequest.new(payment_slip)
      }.to_not raise_error
      expect {
        new_payment_slip.send
      }.to_not raise_error
    end
  end

  describe 'Retrieving a slip' do
    before :each do
      @@grac_client = nil
    end

    it 'set the grac_client client correctly' do
      request_client = double('Dummy Request Client')
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect(request_client).to receive(:path).with('/slips/{id}', { id: '1' }).and_return(request_client)
      expect(request_client).to receive(:get).and_return({})
      Barzahlen.retrieve_slip('1')
    end
  end

  describe 'Updating a slip' do
    before :each do
      @@grac_client = nil
    end

    it 'set the grac_client client correctly' do
      request_client = double('Dummy Request Client')
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect(request_client).to receive(:path).with('/slips/{id}', { id: '1' }).and_return(request_client)
      expect(request_client).to receive(:patch).with({}).and_return({})
      Barzahlen.update_slip(1, {})
    end
  end

  describe 'Resend a slip mail' do
    before :each do
      @@grac_client = nil
    end

    it 'set the grac_client client correctly' do
      request_client = double('Dummy Request Client')
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect(request_client).to receive(:path).with('/slips/{id}/resend/email', { id: '1' }).and_return(request_client)
      expect(request_client).to receive(:post).and_return({})
      Barzahlen.resend_email(1)
    end
  end

  describe 'Resend a slip text message' do
    before :each do
      @@grac_client = nil
    end

    it 'set the grac_client client correctly' do
      request_client = double('Dummy Request Client')
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect(request_client).to receive(:path).with('/slips/{id}/resend/text_message', { id: '1' }).and_return(request_client)
      expect(request_client).to receive(:post).and_return({})
      Barzahlen.resend_text_message(1)
    end
  end

  describe 'Invalidate a slip' do
    before :each do
      @@grac_client = nil
    end

    it 'set the grac_client client correctly' do
      request_client = double('Dummy Request Client')
      expect(Grac::Client).to receive(:new).and_return(request_client)
      expect(request_client).to receive(:path).with('/slips/{id}/invalidate', { id: '1' }).and_return(request_client)
      expect(request_client).to receive(:post).and_return({})
      Barzahlen.invalidate_slip(1)
    end
  end

  describe 'Webhook request' do
    let(:request) {
      return {
        'Bz-Hook-Format' => 'v2',
        'Host' => 'callback.example.com',
        'Path' => '/barzahlen/callback',
        'Port' => '443',
        'Date' => 'Fri, 01 Apr 2016 09:20:06 GMT',
        'Method' => 'POST',
        'Bz-Signature' => 'BZ1-HMAC-SHA256 eb22cda264a5cf5a138e8ac13f0aa8da2daf28c687d9db46872cf777f0decc04',
        'Body' => '{
    "event": "paid",
    "event_occurred_at": "2016-01-06T12:34:56Z",
    "affected_transaction_id": "4729294329",
    "slip": {
        "id": "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
        "slip_type": "payment",
        "division_id": "1234",
        "reference_key": "O64737X",
        "expires_at": "2016-01-10T12:34:56Z",
        "customer": {
            "key": "LDFKHSLFDHFL",
            "cell_phone_last_4_digits": "6789",
            "email": "john@example.com",
            "language": "de-DE"
        },
        "metadata": {
          "order_id": 1234,
          "invoice_no": "A123"
        },
        "transactions": [
          {
            "id": "4729294329",
            "currency": "EUR",
            "amount": "123.34",
            "state": "paid"
          }
        ]
    }
}'
      }
    }

    before do
      Barzahlen.configure do |config|
        config.payment_key = '6b3fb3abef828c7d10b5a905a49c988105621395'
      end
    end

    it 'refuses if the api version is v1 and returns nil' do
      request['Bz-Hook-Format'] = 'v1'
      expect(Barzahlen.webhook_request(request)).to eq(nil)
    end

    it 'refuses if the signature is invalid and raises exception' do
      request['Host'] = 'Unknown'
      expect {
        Barzahlen.webhook_request(request)
      }.to raise_error(Barzahlen::Error::SignatureError)
    end

    it 'refuses if the path is invalid and raises exception' do
      request['Path'] = 'Unknown'
      expect {
        Barzahlen.webhook_request(request)
      }.to raise_error(Barzahlen::Error::SignatureError)
    end

    it 'works without method' do
      request.delete('Method')
      expect {
        Barzahlen.webhook_request(request)
      }.to_not raise_error
    end

    it 'works without port' do
      request.delete('Port')
      expect {
        Barzahlen.webhook_request(request)
      }.to_not raise_error
    end

    it 'succeeds and returns valid Hash' do
      valid_hash = Barzahlen.webhook_request(request)
      expect(valid_hash).to be_an(Hash)
    end
  end
end
