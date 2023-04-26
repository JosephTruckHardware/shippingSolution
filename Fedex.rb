require "faraday"
require "uri"
require "json"
require "date"

class FedexAPI

  Token_url = "https://apis-sandbox.fedex.com/oauth/token"
  Validate_address_url = "https://apis-sandbox.fedex.com/address/v1/addresses/resolve"
  Shipment_url = "https://apis-sandbox.fedex.com/ship/v1/shipments"
  Tracker_url = "https://apis-sandbox.fedex.com/track/v1/associatedshipments"
  Rates_url = "https://apis-sandbox.fedex.com/rate/v1/rates/quotes"
  Account_number = "740561073"
  Duty_account_number = "189090706"
  # Account number for tracking number in sandbox mode
  # Account_number = '510088000'

  def initialize

  end

  def get_rates(shipment)
    if rates_current?(shipment)
      previous_rates = JSON.parse(shipment.rate_response)
      previous_rates["fedex"]["rates"]
    else
      get_shipping_rates_international(shipment)
    end
  end

  # def get_rates(shipment)
  #   if rates_current?(shipment)
  #     puts "rates are current"
  #     if shipment.rate_response["rates"][0]["Fedex"].nil?
  #       shipment.rate_response["rates"][0]["Fedex"]
  #     else 
  #       puts "No rates found"
  #       get_shipping_rates(shipment)
  #     end
  #   else
  #     get_shipping_rates_international(shipment)
  #   end
  # end

  def rates_current?(shipment)
    rates = JSON.parse(shipment.rate_response)
    if rates['date'].nil?
      puts 'rates do not exist'
      false
    elsif
      if DateTime.parse(rates["date"]) >= (Date.today - 1)
        puts 'rates are current'
        true
      else
        puts 'rates are not current'
        false
      end
    else
      puts 'rates are not current'
      false
    end
  end

  def get_token
    token = DB[:tokens].where { token_expires_at > Sequel::CURRENT_TIMESTAMP }.first
    if !token.nil? && token[:token_number] != ""
      puts "token still valid"
      token[:token_number]
    else
      puts "No token found, getting new token"
      get_new_token
    end
  end

  def get_new_token
    token = Faraday.post(Token_url) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = URI.encode_www_form({
        grant_type: "client_credentials",
        client_id: "l79149839ea2ba46bab4a0788ae14bead7",
        client_secret: "f1d86a21671640f184423f2e2c0c37d0"
      })
    end

    if token.status == 200
      token = Token.new(token_number: JSON.parse(token.body)["access_token"], token: JSON.parse(token.body))
      puts "New token received"
      token.save
      token.token_number
    else
      puts "Error getting token: #{JSON.parse(token.body)}"
      get_new_token
    end
  end

  def validate_address(address, city, startOrProvince, postalCode, countryCode)
    address_data = {
      addressesToValidate: [
        {
          address: {
            streetLines: [
              address
            ],
            city: city,
            stateOrProvinceCode: startOrProvince,
            postalCode: postalCode,
            countryCode: countryCode
          }
        }
      ]
    }

    validate = Faraday.post(Validate_address_url) do |req|
      req.headers["content-type"] = "application/json"
      req.headers["authorization"] = "Bearer " + get_token
      req.headers["x-locale"] = "en_CA"
      req.body = address_data.to_json
    end

    if validate.status == 200
      puts "Success: " + validate.body
      validate
    else
      puts "Failed: " + validate.body
      "This is not a valid address"
    end
  end

  def create_new_shipment(shipment_id)
    shipment = Shipment[shipment_id]
    shipping_to = Address[shipment.shipping_to_address_id]
    shipping_from = Address[shipment.shipping_from_address_id]
    billed_address = Address[shipment.billed_address_id]

    shipment_data = {
      labelResponseOptions: "URL_ONLY",
      requestedShipment: {
        shipper: {
          contact: {
            personName: shipping_from.name,
            phoneNumber: shipping_from.phone_number,
            companyName: shipping_from.name
          },
          address: {
            streetLines: [
              shipping_from.address_line_1
            ],
            city: shipping_from.city,
            stateOrProvinceCode: shipping_from.state_code,
            postalCode: shipping_from.postal_code,
            countryCode: shipping_from.country
          }
        },
        recipients: [
          {
            contact: {
              personName: shipping_to.name,
              phoneNumber: shipping_to.phone_number,
              companyName: shipping_to.name
            },
            address: {
              streetLines: [
                shipping_to.address_line_1
              ],
              city: shipping_to.city,
              stateOrProvinceCode: shipping_to.state_code,
              postalCode: shipping_to.postal_code,
              countryCode: shipping_to.country
            }
          }
        ],
        #   "shipDatestamp": "2023-03-28",
        serviceType: "FEDEX_GROUND",
        packagingType: "YOUR_PACKAGING",
        pickupType: "USE_SCHEDULED_PICKUP",
        blockInsightVisibility: false,
        shippingChargesPayment: {
          paymentType: "SENDER"
        },
        labelSpecification: {
          imageType: "PDF",
          labelStockType: "PAPER_85X11_TOP_HALF_LABEL"
        },
        requestedPackageLineItems: [
          {
            weight: {
              units: "KG",
              value: "5"
            }
          }
        ]
      },
      accountNumber: {
        value: Account_number
      }
    }

    shipment = Faraday.post(Shipment_url) do |req|
      req.headers["content-type"] = "application/json"
      req.headers["authorization"] = "Bearer " + get_token
      req.headers["x-locale"] = "en_CA"
      req.body = shipment_data.to_json
    end

    if shipment.status == 200
      puts "Success: " + shipment.body
      shipment
    else
      puts "Failed: " + shipment.body
      "Error making new shipment"
    end
  end

  def track_shipment(tracking_number)
    tracker_data = {
      masterTrackingNumberInfo: {
        trackingNumberInfo: {
          trackingNumber: tracking_number
        }
      },
      associatedType: "STANDARD_MPS"
    }

    tracker = Faraday.post(Tracker_url) do |req|
      req.headers["content-type"] = "application/json"
      req.headers["authorization"] = "Bearer " + get_token
      req.headers["x-locale"] = "en_CA"
      req.body = tracker_data.to_json
    end

    if tracker.status == 200
      puts "Success: " + tracker.body
      tracker
    else
      puts "Failed: " + tracker.body
      "Error tracking shipment"
    end
  end

  def get_shipping_rates_international(shipment)
    shipping_to = Address[shipment.shipping_to_address_id]
    shipping_from = Address[shipment.shipping_from_address_id]
    billed_address = Address[shipment.billed_address_id]
    parcels = shipment.parcels

    items_hash = []

    parcels.each do |parcel|
      items = parcel.get_items_detailed
      items.each do |item|
        item_hash = {
          "groupPackageCount" => 1,
          "weight" => {
            "units" => "LB",
            "value" => item[:weight]
          }
        }
        items_hash << item_hash
      end
    end

    shipment_data = {
      accountNumber: {
        value: Account_number
      },
      requestedShipment: {
        shipper: {
          address: {
            postalCode: shipping_to.postal_code,
            countryCode: shipping_to.country
          }
        },
        recipient: {
          address: {
            # postalCode: shipping_from.postal_code,
            # countryCode: shipping_from.country
            postalCode: "84041",
            countryCode: "US"
          }
        },
        pickupType: "USE_SCHEDULED_PICKUP",
        rateRequestType: [
          "LIST",
          "ACCOUNT"
        ],
        customsClearanceDetail: {
          dutiesPayment: {
            payor: {
              responsibleParty: {
                accountNumber: {
                  value: Duty_account_number
                }
              }
            }
          },
          commodities: [
            {
              description: "MUDFLAP TEST",
              quantity: shipment.get_total_item_count,
              quantityUnits: "PCS",
              weight: {
                units: "LB",
                value: shipment.get_total_weight
              },
              customsValue: {
                amount: shipment.get_total_value,
                currency: "USD"
              }
            }
          ]
        },
        requestedPackageLineItems: []
      }
    }

    shipment_data[:requestedShipment][:requestedPackageLineItems] = []

    shipment_data[:requestedShipment][:requestedPackageLineItems] = items_hash

    puts shipment_data

    shipment_data = JSON.generate(shipment_data)

    rates = Faraday.post(Rates_url) do |req|
      req.headers["content-type"] = "application/json"
      req.headers["authorization"] = "Bearer " + get_token
      req.headers["x-locale"] = "en_CA"
      req.body = shipment_data
    end

    if rates.status == 200
      puts "Success: "

      new_rates = rates.body["output"]["rateReplyDetails"]

      puts new_rates

      new_rate_response = {
        "date" => DateTime.now,
        "rates" => [
          new_rates.each do |rate|
            {
              "service_name" => rate[:serviceName],
              "service_code" => rate[:serviceType],
              "total_price" => rate[:ratedShipmentDetails][0][:totalNetCharge],
              "currency" => rate[:ratedShipmentDetails][0][:currency],
              # "est_delivery_date" => rate[:ratedShipmentDetails][0][:currency],
            }
          end
        ]
      }.to_json

      shipment.rate_response["fedex"] = {
        "date" => nil,
        "rates" => nil,
        "errors" => nil,
      }

      shipment.rate_response['fedex'] = new_rate_response

      shipment.save

      # shipment.rate_response["rates"][0]["Fedex"] = []
      # shipment.rate_response["date"] = DateTime.now.to_json
      # shipment.rate_response["rates"][0]["Fedex"] << JSON.parse(rates.body["output"]["rateReplyDetails"])
      # shipment.save
      # rates = JSON.parse(rates.body)
      # rates["output"]["rateReplyDetails"]
      # shipment.rate_response["rates"][0]["Fedex"]

    else
      puts "Failed: " + rates.body
      "Error"
    end
  end
end