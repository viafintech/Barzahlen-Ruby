# frozen_string_literal: true

require 'spec_helper'
require 'json'

module Barzahlen
  module Error
    describe ClientError do
      it 'should be of type StandardError' do
        exception = Barzahlen::Error::ClientError.new('Client has failed')

        expect(exception).to be_an(StandardError)
      end

      it 'creates error message correctly' do
        exception = Barzahlen::Error::ClientError.new('The client has failed absolutely.')

        expect(exception.message).to eq('The client has failed absolutely.')
        expect(exception.to_s).to eq('The client has failed absolutely.')
      end
    end

    describe SignatureError do
      it 'should be instanceable and sets the variables correctly' do
        exception = Barzahlen::Error::SignatureError.new('The self generated signature is not complying to the provided signature.')

        expect(exception.message).to eq('The self generated signature is not complying to the provided signature.')
        expect(exception.to_s).to eq('The self generated signature is not complying to the provided signature.')
      end
    end

    describe ApiError do
      let(:response) {
        return {
          error_class: 'invalid_parameter',
          error_code: 'reference_key_already_exists',
          message: 'The given reference key already exists - use another one.',
          documentation_url: 'https://www.barzahlen.de/',
          request_id: '64ec26b27d414a66b87f2ec7cad7e92c'
        }
      }

      it 'should be of type ApiError' do
        error_class = Barzahlen::Error.generate_error_from_response(response.to_json)

        expect(error_class).to be_an(StandardError)
      end

      it 'generate invalid_parameter class from json' do
        error_class = Barzahlen::Error.generate_error_from_response(response.to_json)
        expect(error_class.class.name).to eq('Barzahlen::Error::InvalidParameterError')
      end

      it 'generate invalid_parameter class from hash with strings' do
        string_hash = Hash[response.map { |k, v| [k.to_s, v] }]
        error_class = Barzahlen::Error.generate_error_from_response(string_hash)
        expect(error_class.class.name).to eq('Barzahlen::Error::InvalidParameterError')
      end

      it 'generate invalid_parameter class from hash with symbols' do
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::InvalidParameterError')
      end

      it 'generate AuthError class' do
        response[:error_class] = 'auth'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::AuthError')
      end

      it 'generate TransportError class' do
        response[:error_class] = 'transport'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::TransportError')
      end

      it 'generate IdempotencyError class' do
        response[:error_class] = 'idempotency'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::IdempotencyError')
      end

      it 'generate RateLimitError class' do
        response[:error_class] = 'rate_limit'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::RateLimitError')
      end

      it 'generate InvalidFormatError class' do
        response[:error_class] = 'invalid_format'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::InvalidFormatError')
      end

      it 'generate InvalidStateError class' do
        response[:error_class] = 'invalid_state'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::InvalidStateError')
      end

      it 'generate NotAllowedError class' do
        response[:error_class] = 'not_allowed'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::NotAllowedError')
      end

      it 'generate ServerError class' do
        response[:error_class] = 'server_error'
        error_class = Barzahlen::Error.generate_error_from_response(response)
        expect(error_class.class.name).to eq('Barzahlen::Error::ServerError')
      end

      it 'generates valid error messages' do
        error_class = Barzahlen::Error.generate_error_from_response(response)

        expect(error_class.message).to eq('Error occurred with: The given reference key already exists - use another one.')
      end

      it 'set error values' do
        error_class = Barzahlen::Error.generate_error_from_response(response)

        expect(error_class.error_class).to eq('invalid_parameter')
        expect(error_class.error_code).to eq('reference_key_already_exists')
        expect(error_class.error_message).to eq('The given reference key already exists - use another one.')
        expect(error_class.documentation_url).to eq('https://www.barzahlen.de/')
        expect(error_class.request_id).to eq('64ec26b27d414a66b87f2ec7cad7e92c')
      end

      it 'has immutable values' do
        error_class = Barzahlen::Error.generate_error_from_response(response)

        expect { error_class.http_status = 1 }.to raise_error(NoMethodError)
        expect { error_class.error_class = 1 }.to raise_error(NoMethodError)
        expect { error_class.error_code = 1 }.to raise_error(NoMethodError)
        expect { error_class.error_message = 1 }.to raise_error(NoMethodError)
        expect { error_class.documentation_url = 1 }.to raise_error(NoMethodError)
        expect { error_class.request_id = 1 }.to raise_error(NoMethodError)
      end

      it 'generate default error message when supplying simple string' do
        error_body = '502 Bad Gateway'
        error_class = Barzahlen::Error.generate_error_from_response(error_body)

        expect(error_class.message).to eq('Error occurred with: Please contact CPS to help us fix that as soon as possible.')
      end
    end
  end
end
