require "uri"
require "json"
require "net/http"
require "./Fedex.rb"
require "./models.rb"

get_new_token()

url = URI("http://127.0.0.1:4567/api/shipments")

http = Net::HTTP.new(url.host, url.port);
request = Net::HTTP::Post.new(url)
request["Content-Type"] = "application/json"
request.body = JSON.dump({
  "shipment": {
    "order_id": "12345",
    "required_date": "2023-04-05",
    "paid_by": "sender"
  },
  "shipping_from": {
    "address_type": "commercial",
    "name": "Truck Hardware",
    "address_line_1": "1530 33 Street N",
    "city": "Lethbridge",
    "state_code": "AB",
    "country": "CA",
    "postal_code": "T1H 5H3",
    "phone_number": "123-456-7890",
    "email": "test@email.com"
  },
  "billing_address": {
    "address_type": "commercial",
    "name": "PERSON NAME",
    "address_line_1": "414 Lake Way",
    "city": "Coalhurst",
    "state_code": "AB",
    "country": "CA",
    "postal_code": "T0L0V2",
    "phone_number": "555-555-1212",
    "email": "test@email.com"
  },
  "shipping_to": {
    "address_type": "residential",
    "name": "PERSON NAME",
    "address_line_1": "11416 79a Ave",
    "city": "Delta",
    "state_code": "BC",
    "country": "CA",
    "postal_code": "V4C1V2",
    "phone_number": "778-246-4455",
    "email": "test@email.com"
  },
  "options": {
    "currency": "USD",
    "invoice_number": "0000212571",
    "single_item_per_parcel": true,
    "invoice_template": "commercial_invoice",
    "paperless_trade": true,
    "paid_by": "third_party",
    "payment_account_number": "167809448",
    "duty_paid_by": "third_party",
    "duty_account_number": "189090706"
  },
  "items": [
    {
      "sku": "12345",
      "order_id": "67890",
      "description": "Widget",
      "weight": 0.5,
      "weight_unit": "lbs",
      "hs_code": 123456,
      "value_amount": 10,
      "value_currency": "USD",
      "origin_country": "US",
      "quantity": 1
    },
    {
      "sku": "67890",
      "order_id": "12345",
      "description": "Gadget",
      "weight": 1.5,
      "weight_unit": "lbs",
      "hs_code": 654321,
      "value_amount": 20,
      "value_currency": "USD",
      "origin_country": "CN",
      "quantity": 2
    }
  ]
})

response = http.request(request)
puts response.read_body
