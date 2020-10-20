# Barzahlen API Client in Ruby

[![Travis Build state](https://api.travis-ci.org/Barzahlen/Barzahlen-Ruby.svg)](https://travis-ci.org/Barzahlen/Barzahlen-Ruby) [![Code Climate](https://codeclimate.com/github/Barzahlen/Barzahlen-Ruby/badges/gpa.svg)](https://codeclimate.com/github/Barzahlen/Barzahlen-Ruby) [![RubyDoc](https://img.shields.io/badge/ruby-doc-green.svg)](http://rubydoc.info/github/Barzahlen/Barzahlen-Ruby) [![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop-hq/rubocop)

The official ruby gem for accessing the [Barzahlen API v2][api_documentation_base].

## Installation

Add this line to your application's gemfile

```ruby
gem 'barzahlen', '~> 2.0.0'
```

Then execute:

```shell
bundle install
```

Or install it yourself by typing

```shell
gem install barzahlen
```

## Configuration Values

The gem's configuration values are as following:

* `Sandbox`: Default = `false`
* `Division ID`: Default = `"not_valid_division_id"`
* `Payment key`: Default = `"not_valid_payment_key"`

Example configuration:

```ruby
require 'barzahlen'

Barzahlen.configure do |config|
  config.sandbox = false
  config.division_id = "12345"
  config.payment_key = "123456789abcdef123456789abcdef123456789a"
end
```

The requests issued by this gem call the api endpoints of Barzahlen, which are stored in constant variables in the configuration.

The `division_id` and the `payment_key` can be found in the [Barzahlen Control Center App][control_center_app] and **must** be set in the configuration if you want to use the gem.

## Idempotency Support

Per default this client lib is also supporting idempotency. An idempotent request is simply sending the same request again. This is very useful if a network failure happens or our system fails to process your request and you can simply resend the request.

For further documentation please refer to the [Barzahlen API v2 Documentation][api_documentation_idempotency].

A `slip request` object has idempotency built in and can be retried (**send**) as often as it is needed as long as the same object is used.

## Functionality (`production` and `sandbox`)

For development purposes the client lib can be set to sandbox mode by setting the `sandbox`-variable in the configuration to true.

For further information please refer to the [Barzahlen API Sandbox Documentation][api_documentation_sandbox]

```ruby
Barzahlen.configure do |config|
  config.sandbox = true
end
```

### Basic Functionality

The following is happening during a request:

1. The [signature][api_documentation_signature], based on the provided `division_id` and `payment_key`, will get created.
2. A https-request is send to the Barzahlen API endpoint.
3. The response is evaluated.
  1. If an error occured, it will try to parse the error, create a client lib exception and throw it.
  2. If everything works fine, the response will be returned as a ruby hash.
4. If a `slip request` object was created, the object can be used for making idempotency requests, by calling **send** on the `slip request` object again.

### Slip Creation

For creating a `refund` or `payment` you first need to generate a slip hash which then can be used to send the slip request.

```ruby
new_payment_slip =  {
                      slip_type: "payment",
                      customer: {
                        key: "<customer-key>"
                      },
                      transactions: [
                        {
                          currency: "<currency>",
                          amount: "<amount>"
                        }
                      ]
                    }
bz_new_payment_slip = Barzahlen::CreateSlipRequest.new(new_payment_slip)
```

A full list of all required and additional variables is available at [Barzahlen Api v2 slip creation documentation][api_documentation_slip].

Afterwards this object can be used to send the `slip request`.

```ruby
bz_new_payment_slip.send
```

#### Refund or Payment

All required and applicable variables for a `refund` or `payment` slip is well documented in the [Barzahlen API v2 slip creation Documentation][api_documentation_slip].

### Retrieve Slip

Retrieving a `slip` is simply done by:

```ruby
Barzahlen.retrieve_slip(slip_id)
```

This will return an object which looks the following:

```ruby
{
  "id" => "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
  "slip_type" => "payment",
  "division_id" => "1234",
  "reference_key" => "O64737X",
  "hook_url" => "https://psp.example.com/hook",
  "expires_at" => "2016-01-10T12:34:56Z",
  "customer" => {
    "key" => "LDFKHSLFDHFL",
    "cell_phone_last_4_digits" => "6789",
    "email" => "john@example.com",
    "language" => "de-DE"
  },
  "metadata" => {
    "order_id" => "1234",
    "invoice_no" => "A123"
  },
  "transactions" => [
    {
      "id" => "4729294329",
      "currency" => "EUR",
      "amount" => "123.34",
      "state" => "pending"
    }
  ]
}
```

For a complete list of all response variables please refer to the [Barzahlen API v2 documentation][api_documentation_retrieve] on how a slip is retrieved.

### Update Slip

For updating a slip, a hash has to be supplied as mentioned prior in the slip section.

For a full list of all variables and their constraints please read the [Barzahlen Api v2 update slip documentation][api_documentation_update].

```ruby
updateable_slip = {
  "customer": {
    "email": "john@example.com",
    "cell_phone": "+495423112345"
  },
  "expires_at": "2016-01-10T12:34:56Z",
  "transactions": [
    {
      "id": "4729294329",
      "amount": "150.00"
    }
  ],
  "reference_key": "NEWKEY"
}
Barzahlen.update_slip(slip_id, updateable_slip)
```

As a result you will get the whole slip as a hash:

```ruby
{
  "id" => "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
  "slip_type" => "payment",
  "division_id" => "1234",
  "reference_key" => "O64737X",
  "hook_url" => "https://psp.example.com/hook",
  "expires_at" => "2016-01-10T12:34:56Z",
  "customer" => {
    "key" => "LDFKHSLFDHFL",
    "cell_phone_last_4_digits" => "6789",
    "email" => "john@example.com",
    "language" => "de-DE"
  },
  "metadata" => {
    "order_id" => "1234",
    "invoice_no" => "A123"
  },
  "transactions" => [
    {
      "id" => "4729294329",
      "currency" => "EUR",
      "amount" => "123.34",
      "state" => "pending"
    }
  ]
}
```

Content can be looked up [here][api_documentation_update].

### Resend Slip Email

Resending a slip email is done as following:

```ruby
Barzahlen.resend_email(slip_id)
```

For further information please refer to the [Barzahlen API v2 resend documentation][api_documentation_resend].

### Resend Slip Text Message

Resending a slip text message is done as following:

```ruby
Barzahlen.resend_text_message(slip_id)
```

For further information please refer to the [Barzahlen API v2 resend documentation][api_documentation_resend].

### Invalidate Slip

Invalidating a slip is done as following:

```ruby
Barzahlen.invalidate_slip(slip_id)
```

As a response you can get:

```ruby
{
  "id" => "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
  "slip_type" => "payment",
  "division_id" => "1234",
  "reference_key" => "O64737X",
  "hook_url" => "https://psp.example.com/hook",
  "expires_at" => "2016-01-10T12:34:56Z",
  "customer" => {
    "key" => "LDFKHSLFDHFL",
    "cell_phone_last_4_digits" => "6789",
    "email" => "john@example.com",
    "language" => "de-DE"
  },
  "metadata" => {
    "order_id" => "1234",
    "invoice_no" => "A123"
  },
  "transactions" => [
    {
      "id" => "4729294329",
      "currency" => "EUR",
      "amount" => "123.34",
      "state" => "pending"
    }
  ]
}
```

For a full list of all response variables please refer to the [Barzahlen API v2 invalidate slip documentation][api_documentation_invalidate].

### Webhook Handling

When a slip is paid or expires, a webhook request is issued to the url you provided individually in the slip or in the [Barzahlen Control Center App][control_center_app].

In sandbox mode you can manually trigger a `paid` or `expired` webhook request in the [Barzahlen Control Center App][control_center_app].

The webhook request is also signed as normal requests to the api with the aforementioned `payment_key`. But don't worry about the signature check because this library will take care of it.

If the signature check is failing a **Barzahlen::Error::SignatureError** is raised.

For further documentation please refer to the [webhooks Barzahlen API v2 documentation][api_documentation_webhooks].

The notification handling is expecting an Object in the following structure:

```ruby
request = {
  "Bz-Hook-Format" => "v2",
  "Host" => "callback.example.com",
  "Path" => "/barzahlen/callback",
  "Port" => "443",
  "Date" => "Fri, 01 Apr 2016 09:20:06 GMT",
  "Method" => "POST",
  "Bz-Signature" => "BZ1-HMAC-SHA256 eb22cda264a5cf5a138e8ac13f0aa8da2daf28c687d9db46872cf777f0decc04",
  "Body" => '{
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
```

Method (default `POST`) and port (default `443`) are optional. (If you want to try out this request, the `payment_key` is `6b3fb3abef828c7d10b5a905a49c988105621395`)

A request of this type can then be passed to the webhook request method:
```ruby
request_hash = Barzahlen.webhook_request(request)
```

The following can happen:

* If the request is an api v1 webhook request: nil is returned.
* If the signature check is not successful: a `SignatureError` is raised.
* If the everything works fine: a hash with the content is returned.

Example hash response:

```ruby
{
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
}
```

For further documentation about webhooks please refer to [webhook documentation][api_documentation_webhooks].

## Interprete Api Error and Return

### Api Client Errors

Errors will be generated and raised based on the [Barzahlen API v2 error response][api_documentation_error] information.

The `error_class`, which is explained on [Barzahlen API v2 Documentation][api_documentation_error] is used as the error name:

* Barzahlen::Error::AuthError
* Barzahlen::Error::TransportError
* Barzahlen::Error::IdempotencyError
* Barzahlen::Error::RateLimitError
* Barzahlen::Error::InvalidFormatError
* Barzahlen::Error::InvalidStateError
* Barzahlen::Error::InvalidParameterError
* Barzahlen::Error::NotAllowedError
* Barzahlen::Error::ServerError
* Barzahlen::Error::UnexpectedError -> Is raised when no interpretation of the error response was possible.

All these Errors are of type `Barzahlen::Error::ApiError`.

If the interpretation was successful you will get an error where you can access the information the following:

```ruby
error.error_class # The error_class from the response which is used as error class name
error.error_code # The error_code from the response
error.message # The message which describes the specific error
error.documentation_url # The documentation url which you can refer to for debugging
error.request_id # The request id which can be used to tell us if we need to help you finding an issue
```

### Signature Check Error

If the generated signature in the webhook implementation is not the same which was send by the Barzahlen API v2, a `Barzahlen::Error::SignatureError` of type `Barzahlen::Error::StandardError` is raised.

## Bugs and Contribution

For bugs and feature requests open an issue on Github. For code contributions fork the repo, make your changes and create a pull request.

### License

[LICENSE](LICENSE) (MIT)

[control_center_app]: https://controlcenter.barzahlen.de
[api_documentation_base]: http://docs.barzahlen.de/api/v2
[api_documentation_idempotency]: http://docs.barzahlen.de/api/v2#idempotency
[api_documentation_signature]: http://docs.barzahlen.de/api/v2#calculating-the-signature
[api_documentation_webhooks]: http://docs.barzahlen.de/api/v2#webhooks
[api_documentation_rate_limit]: http://docs.barzahlen.de/api/v2#rate-limiting
[api_documentation_sandbox]: http://docs.barzahlen.de/api/v2#sandbox
[api_documentation_slip]: http://docs.barzahlen.de/api/v2#create-slip
[api_documentation_retrieve]: http://docs.barzahlen.de/api/v2#retrieve-slip
[api_documentation_update]: http://docs.barzahlen.de/api/v2#update-slip
[api_documentation_resend]: http://docs.barzahlen.de/api/v2#resend-email-text-message
[api_documentation_invalidate]: http://docs.barzahlen.de/api/v2#invalidate-slip
[api_documentation_error]: http://docs.barzahlen.de/api/v2#errors
