require "savon"
require "net/http"
require "xmlsimple"
require "json"
require_relative "models"

Development_key = "7c4034699ff8406191794f1af15b8e57"
Password = "nWzJcm]}"
BillingAccountNumber = "9999999999"

def create_shipment_domestic(shipment)
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

  client.operations

  response = client.call(:create_shipment, message: {
                                                "v2:Shipment": {
                                                  "v2:SenderInformation": {
                                                      "v2:Address": {
                                                      "v2:Name": shipment.get_shipping_from.name.upcase,
                                                      "v2:StreetNumber": shipment.get_shipping_from.get_street_number,
                                                      "v2:StreetName": shipment.get_shipping_from.get_street_name.upcase,
                                                      "v2:City": shipment.get_shipping_from.city.upcase,
                                                      "v2:Province": shipment.get_shipping_from.state_code.upcase,
                                                      "v2:Country": shipment.get_shipping_from.country.upcase,
                                                      "v2:PostalCode": shipment.get_shipping_from.postal_code_stripped,
                                                      "v2:PhoneNumber": {
                                                        "v2:CountryCode": "1",
                                                        "v2:AreaCode": shipment.get_shipping_from.get_area_code,
                                                        "v2:Phone": shipment.get_shipping_from.get_rest_of_phone_number,
                                                      },
                                                    },
                                                  },
                                                  "v2:ReceiverInformation": {
                                                    "v2:Address": {
                                                      "v2:Name": shipment.get_shipping_to.name.upcase,
                                                      "v2:StreetNumber": shipment.get_shipping_to.get_street_number,
                                                      "v2:StreetName": shipment.get_shipping_to.get_street_name.upcase,
                                                      "v2:City": shipment.get_shipping_to.city.upcase,
                                                      "v2:Province": shipment.get_shipping_to.state_code.upcase,
                                                      "v2:Country": shipment.get_shipping_to.country.upcase,
                                                      "v2:PostalCode": shipment.get_shipping_to.postal_code_stripped,
                                                      "v2:PhoneNumber": {
                                                        "v2:CountryCode": "1",
                                                        "v2:AreaCode": shipment.get_shipping_to.get_area_code,
                                                        "v2:Phone": shipment.get_shipping_to.get_rest_of_phone_number,
                                                      },
                                                    },
                                                  },
                                                  "v2:PackageInformation": {
                                                    "v2:ServiceID": "PurolatorExpress",
                                                    "v2:TotalWeight": {
                                                      "v2:Value": shipment.get_total_weight,
                                                      "v2:WeightUnit": "kg",
                                                    },
                                                    "v2:TotalPieces": shipment.parcels.count,
                                                    # "v2:OptionsInformation": {
                                                    #   "v2:Options": {
                                                    #     "v2:OptionID": "COD",
                                                    #     "v2:Value": "100",
                                                    #   },
                                                    # },
                                                    "v2:PiecesInformation": {
                                                      "v2:Piece": {
                                                        "v2:Description": "Item Description",
                                                        "v2:Quantity": 1,
                                                        "v2:Weight": {
                                                          "v2:Value": 1,
                                                          "v2:WeightUnit": "kg",
                                                        },
                                                        "v2:Length": {
                                                          "v2:Value": 1,
                                                          "v2:DimensionUnit": "cm",
                                                        },
                                                        "v2:Width": {
                                                          "v2:Value": 1,
                                                          "v2:DimensionUnit": "cm",
                                                        },
                                                        "v2:Height": {
                                                          "v2:Value": 1,
                                                          "v2:DimensionUnit": "cm",
                                                        },
                                                      },
                                                    },
                                                  },
                                                  "v2:PaymentInformation": {
                                                    "v2:PaymentType": "Sender",
                                                    "v2:RegisteredAccountNumber": BillingAccountNumber,
                                                  },
                                                  "v2:PickupInformation": {
                                                    "v2:PickupType": "DropOff",
                                                    "v2:PickupAddress": {
                                                      "v2:Name": "Sender Name",
                                                      "v2:StreetNumber": "123",
                                                      "v2:StreetName": "Main Street",
                                                      "v2:City": "Toronto",
                                                      "v2:Province": "ON",
                                                      "v2:Country": "CA",
                                                      "v2:PostalCode": "M1M1M1",
                                                      "v2:PhoneNumber": {
                                                        "v2:CountryCode": "1",
                                                        "v2:AreaCode": "416",
                                                        "v2:Phone": "1234567",
                                                      },
                                                    },
                                                  },
                                                },
                                                "v2:PrinterType": "Thermal",
                                              })

  response.hash
end

def get_quick_estimate_domestic(shipment)
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

  response.hash
end

def get_quick_estimate_international()
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

  puts client.inspect

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

  response.hash
end
