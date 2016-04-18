[control_center_app]: control-center.barzahlen.de
[api_online_v2_documentation]: barzahlen.de/api-documentation
[rails_response]: http://edgeguides.rubyonrails.org/action_controller_overview.html#the-response-object

# Barzahlen Ruby Online API V2 Client

The official ruby gem for accessing the new Barzahlen (CPS) API Online V2.

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

The gems configuration values are following:  
* Sandbox: Default = false
* Division ID: Mandatory
* Payment key: Mandatory

The calls from this gem normally go to the live api endpoints of barzahlen which are stored in constant variables in the configuration.  
The Division ID and the Payment Key can be gathered from the Barzahlen [Control Center App][control_center_app] and must be entered if you want to use the gem.

## Enforce https

Per default the ssl connection-endpoints of the Barzahlen API Online V2 are used. We discourage forcefully overriding the values because of security issues which could arise.

## Idempotency support build in

Per default this client lib is also supporting idempotency as stated in the [Api Online V2 Documentation][api_online_v2_documentation].  
The creation of a refund or payment slip can be retried as often as it is needed as far as the same object (Slip) is taken.

## Signature generation

The creation of the signature as stated in the [Api Online V2 Documentation][api_online_v2_documentation] is automatically taken care of by this client lib on the fly.

## Functionality (production and sandbox)

The client lib can be used in production and sandbox mode. Per default the client lib will use the production endpoints.  
For development purposes the client lib can be set to sandbox mode by setting the sandbox-variable in the configuration to true.

```Ruby
BarzahlenV2.configure do |config|
  config.sandbox = true
end
```

### Basic Functionality

Following is happening during a request:  
1. The Signature will get created (for the complete setup please refer to [Api Online V2 Documentation][api_online_v2_documentation])  
2. An https-request is send to the barzahlen api endpoint (depending on the sandbox configuration)  
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
4. If it was creating a refund or payment the slip object can be used for making idempotency requests.

### Slip

For creating a refund or payment you first need to generate a slip hash which then can be used to create the actual slip.  

```Ruby
new_payment_slip =  {
                      slip_type: "payment",
                      customer: {
                        key: "<customer-key>"
                      },
                      transaction: [
                        {
                          currency: "<currency>",
                          amount: "<amount>"
                        }
                      ]
                    }
bz_new_payment_slip = BarzahlenV2::Slip.new(new_payment_slip)
```

For the correct variables please refer to the [Api Online V2 Documentation][api_online_v2_documentation].

Afterwards this object can be used to create the slip and also use it for idempotency.

```Ruby
bz_new_payment_slip.create
```

#### refund or payment

The only difference for creating a refund or payment is by supplying either "payment" or "refund" as slip_type.

### retrieve slip

Retrieving a slip is simply done like this:

```Ruby
BarzahlenV2::Online.retrieve_slip(slip_id)
```

### Update Slip

For updating a slip a hash has to be supplied as mentioned prior in the slip section. It is important to only supply the mandatory values and the values which need to change. Supplying "nil" or "null" will set the variable to null on our backend systems. Also keep in mind that if you change e-mail or the telephone number an e-mail is send out or it could be possible that it triggers a resend of a text message. (Further reading on [Api Online V2 Documentation][api_online_v2_documentation])

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
BarzahlenV2::Online.update_slip(slip_id, updateable_slip)
```

### resend slip

Resending an e-mail or text message is done following:

```Ruby
BarzahlenV2::Online.resend_slip(slip_id, message_type)
```

Message type can be one of:  
* e-mail
* text-message

Also keep in mind that resending a text message can be not possible because of an exceeded text message sending count.

### Invalidate Slip

Invalidating a slip is done following:

```Ruby
BarzahlenV2::Online.invalidate_slip(slip_id)
```

### Notification Handling

The notification handling is expecting a standard [rails response][rails-response] can be used by simply doing the following:

```Ruby
response_hash = BarzahlenV2::Online.webhook_request(response)
```

Following can happen:
* If the request is an api v1 webhook request was issued nil is returned
* If the content type is something else than json nil is returned
* If the signature comparison is not valid a SignatureError is raised
* If the everything works fine a hash with the content is returned

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

Errors will be generated and raised based on the api online v2 error response information.

The error_class which is explained on [Api Online V2 Documentation][api_online_v2_documentation] will be used as the class name of the error.

If the interpretation was successfully you will get an error where you can access the information following

```Ruby
error.error_class # The error_class from the response which is used as error class name
error.error_code # The error_code from the response
error.message # The message which describes the specific error
error.documentation_url # The documentation url which you can refer to for debugging
error.request_id # The request id which can be used to tell us if we need to help you finding an issue
```

A custom ArgumentMissing Error is thrown if you forgot to supply a mandatory value.
