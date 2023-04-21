require "savon"
require "json"
require "nokogiri"

class PurolatorAPI

  Development_key = "7c4034699ff8406191794f1af15b8e57"
  Password = "nWzJcm]}"
  BillingAccountNumber = "9999999999"

  def initialize

  end

  def create_shipment(shipment, service)
    client = Savon.client(
      wsdl: "https://devwebservices.purolator.com/EWS/V2/Shipping/ShippingService.wsdl",
      basic_auth: [Development_key, Password],
      # env_namespace: 'http://schemas.xmlsoap.org/soap/envelope/',
      namespace: "http://purolator.com/pws/datatypes/v2",
      namespace_identifier: "v2",
      pretty_print_xml: true,
      log: true,
      log_level: :debug,
      soap_header: {
        "v2:RequestContext" => {
          "v2:Version" => "2.2",
          "v2:Language" => "en",
          "v2:GroupID" => "xxx",
          "v2:RequestReference" => "Rating",
        },
      },
    )

    response = client.call(:create_shipment, message: {
                                                  "v2:Shipment": get_shipment_hash(shipment, service),
                                                  "v2:PrinterType": "Thermal",
                                                })

    response.hash
  end

  def get_quick_estimate(shipment)
    client = Savon.client(
      wsdl: "https://devwebservices.purolator.com/EWS/V2/Estimating/EstimatingService.wsdl",
      basic_auth: [Development_key, Password],
      # env_namespace: 'http://schemas.xmlsoap.org/soap/envelope/',
      namespace: "http://purolator.com/pws/datatypes/v2",
      namespace_identifier: "v2",
      pretty_print_xml: true,
      log: true,
      log_level: :debug,
      soap_header: {
        "v2:RequestContext" => {
          "v2:Version" => "2.2",
          "v2:Language" => "en",
          "v2:GroupID" => "xxx",
          "v2:RequestReference" => "Rating",
        },
      },
    )
    
    response = client.call(:get_quick_estimate, message: {
                                                  "v2:BillingAccountNumber": BillingAccountNumber,
                                                  "v2:SenderPostalCode": shipment.get_shipping_from.postal_code,
                                                  "v2:ReceiverAddress": {
                                                    "v2:City": shipment.get_shipping_to.city.upcase,
                                                    "v2:Province": shipment.get_shipping_to.state_code.upcase,
                                                    "v2:Country": shipment.get_shipping_to.country.upcase,
                                                    "v2:PostalCode": shipment.get_shipping_to.postal_code.upcase,
                                                  },
                                                  "v2:PackageType": "CustomerPackaging",
                                                  "v2:TotalWeight": {
                                                    "v2:Value": shipment.get_total_weight,
                                                    "v2:WeightUnit": "kg",
                                                  },
                                                })

    response.body[:get_quick_estimate_response][:shipment_estimates][:shipment_estimate]

  end

  def get_full_estimate(shipment)
    client = Savon.client(
      wsdl: "https://devwebservices.purolator.com/EWS/V2/Estimating/EstimatingService.wsdl",
      basic_auth: [Development_key, Password],
      # env_namespace: 'http://schemas.xmlsoap.org/soap/envelope/',
      namespace: "http://purolator.com/pws/datatypes/v2",
      namespace_identifier: "v2",
      pretty_print_xml: true,
      log: true,
      log_level: :debug,
      soap_header: {
        "v2:RequestContext" => {
          "v2:Version" => "2.2",
          "v2:Language" => "en",
          "v2:GroupID" => "xxx",
          "v2:RequestReference" => "Rating",
        },
      },
    )
    
    response = client.call(:get_full_estimate, message: {
                                                "v2:Shipment": get_shipment_estimate_hash(shipment),
                                                "v2:ShowAlternativeServicesIndicator": true,
    })

    response.hash
  end

  def get_shipment_hash(shipment)
    hash = {
      "v2:SenderInformation": {
        "v2:Address": get_address_hash(shipment.get_shipping_from)
      },
      "v2:ReceiverInformation": {
        "v2:Address": get_address_hash(shipment.get_shipping_to)
      },
      "v2:PackageInformation": {
        "v2:ServiceID": "PurolatorGroundU.S.",
        "v2:TotalWeight": {
          "v2:Value": shipment.get_total_weight,
          "v2:WeightUnit": "kg",
        },
        "v2:TotalPieces": shipment.parcels.count,
        "v2:PiecesInformation": shipment.parcels.map do |parcel|
          {
            "v2:Piece": {
              "v2:Description": parcel.get_items_detailed[0][:description],
              "v2:Quantity": parcel.get_items[0][:quantity],
              "v2:Weight": {
                "v2:Value": parcel.weight,
                "v2:WeightUnit": parcel.weight_unit
              },
              "v2:Length": {
                "v2:Value": parcel.length,
                "v2:DimensionUnit": parcel.dimension_unit
              },
              "v2:Width": {
                "v2:Value": parcel.width,
                "v2:DimensionUnit": parcel.dimension_unit
              },
              "v2:Height": {
                "v2:Value": parcel.height,
                "v2:DimensionUnit": parcel.dimension_unit
              }
            }
          }
        end
      },
      "v2:InternationalInformation": {
        "v2:DocumentsOnlyIndicator": false,
        "v2:ContentDetails": {
          "v2:Description": "Gift",
          "v2:HarmonizedCode": "123456",
          "v2:CountryOfManufacture": "CA",
          "v2:ProductCode": "Merchandise",
          "v2:UnitValue": "100",
          "v2:Quantity": "1",
          "v2:USMCADDocumentIndicator": false,
          "v2:FDADDocumentIndicator": false,
          "v2:FCCDocumentIndicator": false,
          "v2:SenderIsProducerIndicator": false,
          "v2:TextileIndicator": false,
        },
        "v2:BuyerInformation": {
          "v2:Address": get_address_hash(shipment.get_shipping_to),
          "v2:TaxNumber": "123456789",
        },
        "v2:PreferredCustomsBroker": "Purolator",
        "v2:DutyInformation": {
          "v2:BillDutiesToParty": "Sender",
          "v2:BusinessRelationship": "NotRelated",
          "v2:Currency": "CAD",
        },
        "v2:ImportExportType": "Permanent",
        "v2:CustomsInvoiceDocumentIndicator": true,
      },
      "v2:PaymentInformation": {
        "v2:PaymentType": "Sender",
        "v2:RegisteredAccountNumber": BillingAccountNumber,
      },
      "v2:PickupInformation": {
        "v2:PickupType": "DropOff",
      },
    }

    hash
  end

  def get_shipment_hash(shipment, service_id)
    hash = {
      "v2:SenderInformation": {
        "v2:Address": get_address_hash(shipment.get_shipping_from)
      },
      "v2:ReceiverInformation": {
        "v2:Address": get_address_hash(shipment.get_shipping_to)
      },
      "v2:PackageInformation": {
        "v2:ServiceID": service_id,
        "v2:TotalWeight": {
          "v2:Value": shipment.get_total_weight,
          "v2:WeightUnit": "kg",
        },
        "v2:TotalPieces": shipment.parcels.count,
        "v2:PiecesInformation": shipment.parcels.map do |parcel|
          {
            "v2:Piece": {
              "v2:Description": parcel.get_items_detailed[0][:description],
              "v2:Quantity": parcel.get_items[0][:quantity],
              "v2:Weight": {
                "v2:Value": parcel.weight,
                "v2:WeightUnit": parcel.weight_unit
              },
              "v2:Length": {
                "v2:Value": parcel.length,
                "v2:DimensionUnit": parcel.dimension_unit
              },
              "v2:Width": {
                "v2:Value": parcel.width,
                "v2:DimensionUnit": parcel.dimension_unit
              },
              "v2:Height": {
                "v2:Value": parcel.height,
                "v2:DimensionUnit": parcel.dimension_unit
              }
            }
          }
        end
      },
      "v2:InternationalInformation": {
        "v2:DocumentsOnlyIndicator": true,
        "v2:ContentDetails": {
          "v2:Description": "Gift",
          "v2:HarmonizedCode": "123456",
          "v2:CountryOfManufacture": "CA",
          "v2:ProductCode": "Merchandise",
          "v2:UnitValue": "100",
          "v2:Quantity": "1",
          "v2:USMCADDocumentIndicator": false,
          "v2:FDADDocumentIndicator": false,
          "v2:FCCDocumentIndicator": false,
          "v2:SenderIsProducerIndicator": false,
          "v2:TextileIndicator": false,
        },
        "v2:BuyerInformation": {
          "v2:Address": get_address_hash(shipment.get_shipping_to),
          "v2:TaxNumber": "123456789",
        },
        "v2:PreferredCustomsBroker": "Purolator",
        "v2:DutyInformation": {
          "v2:BillDutiesToParty": "Sender",
          "v2:BusinessRelationship": "NotRelated",
          "v2:Currency": "CAD",
        },
        "v2:ImportExportType": "Permanent",
        "v2:CustomsInvoiceDocumentIndicator": true,
      },
      "v2:PaymentInformation": {
        "v2:PaymentType": "Sender",
        "v2:RegisteredAccountNumber": BillingAccountNumber,
      },
      "v2:PickupInformation": {
        "v2:PickupType": "DropOff",
      },
    }

    hash
  end

  # Returns a hash of the address
  def get_address_hash(address)
    hash = {
      "v2:Name": address.name.upcase,
      "v2:StreetNumber": address.get_street_number,
      "v2:StreetName": address.get_street_name.upcase,
      "v2:City": address.city.upcase,
      "v2:Province": address.state_code.upcase,
      "v2:Country": address.country.upcase,
      "v2:PostalCode": address.postal_code_stripped,
      "v2:PhoneNumber": {
        "v2:CountryCode": "1",
        "v2:AreaCode": address.get_area_code,
        "v2:Phone": address.get_rest_of_phone_number,
      }
    }

    hash
  end
end