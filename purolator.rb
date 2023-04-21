require "savon"
require "net/http"
require "xmlsimple"
require "json"

Development_key = "7c4034699ff8406191794f1af15b8e57"
Password = "nWzJcm]}"
BillingAccountNumber = "9999999999"

def get_quick_estimate()
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
                                                "v2:SenderPostalCode": "T1H5H3",
                                                "v2:ReceiverAddress": {
                                                  "v2:City": "COALHURST",
                                                  "v2:Province": "AB",
                                                  "v2:Country": "CA",
                                                  "v2:PostalCode": "T0L0V2",
                                                },
                                                "v2:PackageType": "CustomerPackaging",
                                                "v2:TotalWeight": {
                                                  "v2:Value": 10,
                                                  "v2:WeightUnit": "lb",
                                                },
                                              })

  response.body
end
