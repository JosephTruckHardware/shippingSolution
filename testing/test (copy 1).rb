require 'faraday'
require 'uri'
require 'json'


data = {
    :grant_type => "client_credentials",
    :client_id => "l79149839ea2ba46bab4a0788ae14bead7",
    :client_secret => "f1d86a21671640f184423f2e2c0c37d0"
}

url = "https://apis-sandbox.fedex.com/oauth/token"

token = Faraday.post(url) do |req|
  req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
  req.body = URI.encode_www_form(data)
end

token_hash = JSON.parse(token.body)

puts token.body

shipment_data = {
  "labelResponseOptions": "URL_ONLY",
  "requestedShipment": {
    "shipper": {
      "contact": {
        "personName": "Test Person",
        "phoneNumber": 1234567890,
        "companyName": "Wilderness Vans"
      },
      "address": {
        "streetLines": [
          "1530 33 St N"
        ],
        "city": "Lethbridge",
        "stateOrProvinceCode": "AB",
        "postalCode": "T1H5H3",
        "countryCode": "CA"
      }
    },
    "recipients": [
      {
        "contact": {
          "personName": "RECIPIENT NAME",
          "phoneNumber": 1234567890,
          "companyName": "Recipient Company Name"
        },
        "address": {
          "streetLines": [
            "414 Lake Way"
          ],
          "city": "Coalhurst",
          "stateOrProvinceCode": "AB",
          "postalCode": "T0L0V2",
          "countryCode": "CA"
        }
      }
    ],
    "shipDatestamp": "2023-03-28",
    "serviceType": "FEDEX_GROUND",
    "packagingType": "YOUR_PACKAGING",
    "pickupType": "USE_SCHEDULED_PICKUP",
    "blockInsightVisibility": false,
    "shippingChargesPayment": {
      "paymentType": "SENDER"
    },
    "labelSpecification": {
      "imageType": "PDF",
      "labelStockType": "PAPER_85X11_TOP_HALF_LABEL"
    },
    "requestedPackageLineItems": [
      {
        "weight": {
            "units": "KG",
            "value": "5"
        }
      }
    ]
  },
  "accountNumber": {
    "value": "740561073"
  }
}

shipment_URL = 'https://apis-sandbox.fedex.com/ship/v1/shipments'

shipment = Faraday.post(shipment_URL) do |req|
  req.headers['content-type'] = 'application/json'
  req.headers['authorization'] = 'Bearer ' + token_hash["access_token"]
  req.headers['x-locale'] = 'en_CA'
  req.body = shipment_data.to_json
end

puts shipment.body

shipment_hash = JSON.parse(shipment.body)

trackingNumber = shipment_hash["output"]["transactionShipments"][0]["pieceResponses"][0]["trackingNumber"]

tracking_data = {
  "masterTrackingNumberInfo": {
    "trackingNumberInfo": {
      "trackingNumber": trackingNumber
    }
  },
  "associatedType": "STANDARD_MPS"
}

puts tracking_data

tracker_URL = 'https://apis-sandbox.fedex.com/track/v1/associatedshipments'

tracker = Faraday.post(shipment_URL) do |req|
  req.headers['content-type'] = 'application/json'
  req.headers['authorization'] = 'Bearer ' + token_hash["access_token"]
  req.headers['x-locale'] = 'en_CA'
  req.body = tracking_data.to_json
end

puts tracker.body