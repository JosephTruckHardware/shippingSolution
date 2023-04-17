require "savon"

Development_key = "7c4034699ff8406191794f1af15b8e57"
Password = "nWzJcm]}"

def get_rates()
    client = Savon.client(wsdl: "https://devwebservices.purolator.com/EWS/V2/Estimating/EstimatingService.wsdl",
    "soap_header" => {
        "ns1:RequestContext" => {
            "ns1:Version" => "1.2",
            "ns1:Language" => "en_US",
            "ns1:GroupID" => "xxx",
            "ns1:RequestReference" => "Rate Request",
        },
        :basic_auth => [Development_key, Password],
        :log => true, :pretty_print_xml => true
    }
    )

    body = {
        "ns1:Shipment" => {
            "ns1:SenderPostalCode" => "L4W 1A1",
            "ns1:ReceiverPostalCode" => "L4W 1A1",
            "ns1:TotalWeight" => {
                "ns1:Value" => 1,
                "ns1:WeightUnit" => "lb"
            },
            "ns1:TotalPieces" => 1,
            "ns1:PickupType" => "DropOff",
            "ns1:ShipmentDate" => "2018-01-01",
            "ns1:PackageType" => "CustomerPackaging",
            "ns1:PaymentInformation" => "Sender",
            "ns1:Items" => {
                "ns1:Item" => {
                    "ns1:Quantity" => 1,
                    "ns1:Weight" => {
                        "ns1:Value" => 1,
                        "ns1:WeightUnit" => "lb"    
                    },
                    "ns1:Length" => {
                        "ns1:Value" => 1,
                        "ns1:DimensionUnit" => "in"
                    },
                    "ns1:Width" => {
                        "ns1:Value" => 1,
                        "ns1:DimensionUnit" => "in"
                    },
                    "ns1:Height" => {
                        "ns1:Value" => 1,
                        "ns1:DimensionUnit" => "in"
                    },
                    "ns1:Description" => "Test"
                }
            }
        }
    }
    client.call(:get_quick_estimate, message: body).body
end