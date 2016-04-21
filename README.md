[control_center_app]: control-center.barzahlen.de
[api_v2_documentation_base]: https://integration.barzahlen.de/en/api
[api_v2_documentation_idempotency]: https://integration.barzahlen.de/en/api#idempotency
[api_v2_documentation_signature]: https://integration.barzahlen.de/en/api#
[api_v2_documentation_slip]: https://integration.barzahlen.de/en/api#calculating-the-signature
[api_v2_documentation_webhooks]: https://integration.barzahlen.de/en/api#webhooks
[api_v2_documentation_rate_limit]: https://integration.barzahlen.de/en/api#rate-limiting
[api_v2_documentation_sandbox]: https://integration.barzahlen.de/en/api#sandbox
[api_v2_documentation_slip]: https://integration.barzahlen.de/en/api#create-slip
[api_v2_documentation_retrieve]: https://integration.barzahlen.de/en/api#retrieve-slip
[api_v2_documentation_update]: https://integration.barzahlen.de/en/api#update-slip
[api_v2_documentation_resend]: https://integration.barzahlen.de/en/api#resend-email-text-message
[api_v2_documentation_invalidate]: https://integration.barzahlen.de/en/api#invalidate-slip
[rails_request]: http://guides.rubyonrails.org/action_controller_overview.html#the-request-object

# Barzahlen Ruby API Client

The official ruby gem for accessing the new Barzahlen (CPS) Barzahlen API V2.

## Installation

Add this line to your application's gemfile

```Ruby
gem 'barzahlen_v2', '~> 0.0.1'
```

Then execute:

```shell
bundle install
```

Or install it yourself by typing

```shell
gem install barzahlen_v2
```

Finally:

```Ruby
require 'barzahlen_v2'
```

## Configuration Values

The gems configuration values are as following:  
* Sandbox: Default = false
* Division ID: Default = "not_valid_division_id"
* Payment key: Default = "not_valid_payment_key"

Example configuration:

```Ruby
BarzahlenV2.configure do |config|
  config.sandbox = false
  config.division_id = "20065"
  config.payment_key = "6b3fb3abef828c7d10b5a905a49c988105621395"
end
```

The calls from this gem go to the api endpoints of barzahlen which are stored in constant variables in the configuration.  
The _Division ID_ and the _Payment Key_ can be found in the [Barzahlen Control Center App][control_center_app] and **must** be set in the configuration if you want to use the gem.

## Enforce https

Per default the ssl connection-endpoints of the Barzahlen Barzahlen API V2 are used.

## Idempotency support build in

Per default this client lib is also supporting idempotency. An idempotent request is simply sending the same request again. This is very very useful if a network failure happens, our system fails to process your request or you exceed your [rate limit][api_v2_documentation_rate_limit] and you can simply resend the request.  
For further documentation please refer to the [Barzahlen API V2 Documentation][api_v2_documentation_idempotency].  
A slip object has idempotency built in and can be retried (**create**d) as often as it is needed as far as the same object is taken.

## Functionality (production and sandbox)

For development purposes the client lib can be set to sandbox mode by setting the sandbox-variable in the configuration to true.  
In sandbox mode every request and also webhooks, which you can issue with the [Control Center App][control_center_app], are simulated. Everything which is produced in this mode obviously cannot be used in production.  
For further information please refer to the [Barzahlen API Sandbox Documentation][api_v2_documentation_sandbox]

```Ruby
BarzahlenV2.configure do |config|
  config.sandbox = true
end
```

### Basic Functionality

Following is happening during a request:  
1. The signature, based on the _division id_ and _payment key_ provided, will get created (for the signature creation please refer to [Barzahlen API V2 Signature Documentation][api_v2_documentation_signature])  
2. A https-request is send to the barzahlen api endpoint  
3. The response is evaluated  
3.1 If an error occured, it will try to parse the error, create a client lib exception and throw it.  
3.2 If everything works fine, the response will be returned as a ruby hash object with the following structure:  

```Ruby
{
  "id" => "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
  "slip_type" => "payment",
  "division_id" => 1234,
  "reference_key" => "O64737X",
  "hook_url" => "https://psp.example.com/hook",
  "expires_at" => "2016-01-10T12:34:56Z",
  "customer" => {
    "key" => "LDFKHSLFDHFL",
    "cell_phone_last_4_digits" => "6789",
    "email" => "john@example.com",
    "language" => "de-DE"
  },
  "checkout_token" => "djF8Y2hrdHxzbHAtMTM4ZWI3NzUtOWY5Yy00NzYwLWI4ZTAtYTNlZWNmYjQ5M2IxfElBSThZMnd6SFYwbjJpMm9aSUpvREpnYnhNS3c5Z2x3elJOanlLblZJeFk9",
  "metadata" => {
    "order_id" => 1234,
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
4. If a slip object was created, the object can be used for making idempotency requests by calling **create** on the slip object again.

### Slip creation

For creating a refund or payment you first need to generate a slip hash which then can be used to create the actual slip.  

```Ruby
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
bz_new_payment_slip = BarzahlenV2::Slip.new(new_payment_slip)
```

A full list of all required and additional variables is available at [Barzahlen Api V2 slip creation Documentation][api_v2_documentation_slip].

Afterwards this object can be used to create the slip and also use it for idempotency.

```Ruby
bz_new_payment_slip.create
```

#### Refund or Payment

The only difference for creating a refund or payment is by supplying either "payment" or "refund" as slip_type.  
All required and applicable variables for a refund or payment slip is well documented in the [Barzahlen API V2 slip creation Documentation][api_v2_documentation_slip].

The slip_object.**create** will return a ruby hash which can look the following:

```Ruby
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
  "checkout_token" => "djF8Y2hrdHxzbHAtMTM4ZWI3NzUtOWY5Yy00NzYwLWI4ZTAtYTNlZWNmYjQ5M2IxfElBSThZMnd6SFYwbjJpMm9aSUpvREpnYnhNS3c5Z2x3elJOanlLblZJeFk9",
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

A full list of all response variables is also available in the [documentation][api_v2_documentation_slip]

### Retrieve Slip

Retrieving a slip is simply done by:

```Ruby
BarzahlenV2.retrieve_slip(slip_id)
```

This will return an object which looks the following:

```Ruby
{
  "id": "slp-d90ab05c-69f2-4e87-9972-97b3275a0ccd",
  "slip_type": "payment",
  "division_id": "1234",
  "reference_key": "O64737X",
  "hook_url": "https://psp.example.com/hook",
  "expires_at": "2016-01-10T12:34:56Z",
  "customer": {
    "key": "LDFKHSLFDHFL",
    "cell_phone_last_4_digits": "6789",
    "email": "john@example.com",
    "language": "de-DE"
  },
  "metadata": {
    "order_id": "1234",
    "invoice_no": "A123"
  },
  "transactions": [
    {
      "id": "4729294329",
      "currency": "EUR",
      "amount": "123.34",
      "state": "pending"
    }
  ]
}
```

For a complete list of all response variables please refer to the [Barzahlen API V2 retrieve documentation][api_v2_documentation_retrieve]

### Update Slip

For updating a slip a hash has to be supplied as mentioned prior in the slip section. It is important to only supply the mandatory values and the values which need to change. Supplying "nil" or "null" will set the variable to null on our systems. Also keep in mind that if you change e-mail or the telephone number an e-mail is send out or it could be possible that it triggers a resend of a text message.  
For a full list of all variables and their constraints please read the [Barzahlen Api V2 update slip documentation][api_v2_documentation_update]

```Ruby
updateable_slip= {
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
BarzahlenV2.update_slip(slip_id, updateable_slip)
```

As a result you will get back a the whole slip as hash:

```Ruby
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

Content can be looked up [here][api_v2_documentation_update]

### Resend email

Resending an e-mail is done as following:

```Ruby
BarzahlenV2.resend_email(slip_id)
```

For further information please refer to the [Barzahlen API V2 resend documentation][api_v2_documentation_resend].

### Resend text_message

Resending a text message is done as following:

```Ruby
BarzahlenV2.resend_text_message(slip_id)
```

Keep in mind that resending a text message can be not possible because of an exceeded text message sending count or if you are using the sandbox mode.

For further information please refer to the [Barzahlen API V2 resend documentation][api_v2_documentation_resend]

### Invalidate Slip

Invalidating a slip is done as following:

```Ruby
BarzahlenV2.invalidate_slip(slip_id)
```

As a response you get for example:

```Ruby
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

For a full list of all response variables please refer to the [Barzahlen API V2 invalidate slip documentation][api_v2_documentation_invalidate]

### Webhook Handling

When a slip is paid or expires a webhook request is issued to the url you provided individually in the slip or in the [Barzahlen Control Center App][control_center_app]. In sandbox mode you can manually trigger a paid or expired webhook request in the [Barzahlen Control Center App][control_center_app].  
The webhook request is also signed as normal requests to the api with the aforementioned _Payment Key_. But don't worry about the signature check because this library will take care of it. If the signature check is not failing a **BarzahlenV2::Error::SignatureError** is raised.  
Be aware that the Barzahlen API is checking your **HTTPS server certificate** when issueing a webhook request, so make sure you have a server certificate which is accepted by common browsers.  
For further documentation please refer to the [webhooks Barzahlen API documentation][api_v2_documentation_webhooks]

The notification handling is expecting a standard [rails request][rails_request] object:

```Ruby
request_hash = BarzahlenV2.webhook_request(request)
```

Following can happen:
* If the request is an api v1 webhook request: nil is returned
* If the content type is something else than json: nil is returned
* If the signature comparison is not valid: a SignatureError is raised
* If the everything works fine: a hash with the content is returned

Example hash return:

```Ruby
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

## Interprete Api Error and return

Errors will be generated and raised based on the [Barzahlen API V2 error response][api_v2_documentation_error] information.

The error_class, which is explained on [Barzahlen API V2 Documentation][api_v2_documentation_error], will be used as the class name of the error as following:

* BarzahlenV2::Error::AuthError
* BarzahlenV2::Error::TransportError
* BarzahlenV2::Error::IdempotencyError
* BarzahlenV2::Error::RateLimitError
* BarzahlenV2::Error::InvalidFormatError
* BarzahlenV2::Error::InvalidStateError
* BarzahlenV2::Error::InvalidParameterError
* BarzahlenV2::Error::NotAllowedError
* BarzahlenV2::Error::ServerError
* BarzahlenV2::Error::UnexpectedError -> Is raised when no interpretation of the error response was impossible

All these Errors are of type BarzahlenV2::Error::ApiError.

If the interpretation was successful you will get an error where you can access the information following

```Ruby
error.error_class # The error_class from the response which is used as error class name
error.error_code # The error_code from the response
error.message # The message which describes the specific error
error.documentation_url # The documentation url which you can refer to for debugging
error.request_id # The request id which can be used to tell us if we need to help you finding an issue
```
