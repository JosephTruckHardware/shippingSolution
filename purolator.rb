require "savon"

Development_key = "7c4034699ff8406191794f1af15b8e57"
Password = "nWzJcm]}"

def get_rates()
  # Set up the Savon client
  client = Savon.client(wsdl: "https://devwebservices.purolator.com/EWS/V2/Estimating/EstimatingService.wsdl",
                        env_namespace: :soapenv,
                        namespace_identifier: :est,
                        pretty_print_xml: true,
                        log: true,
                        log_level: :debug)

  # Build the request XML
  xml_request = <<~XML
        <est:EstimateShipmentRequest>
    <est:Shipment>
<est:SenderInformation>
<est:Address>
<est:City>Toronto</est:City>
<est:Province>ON</est:Province>
<est:Country>CA</est:Country>
<est:PostalCode>M5V2J4</est:PostalCode>
</est:Address>
</est:SenderInformation>
<est:ReceiverInformation>
<est:Address>
<est:City>Vancouver</est:City>
<est:Province>BC</est:Province>
<est:Country>CA</est:Country>
<est:PostalCode>V6B4N9</est:PostalCode>
</est:Address>
</est:ReceiverInformation>
<est:PackageInformation>
<est:Weight>
<est:Value>10</est:Value>
</est:Weight>
<est:Dimensions>
<est:Length>10</est:Length>
<est:Width>10</est:Width>
<est:Height>10</est:Height>
</est:Dimensions>
</est:PackageInformation>
<est:ServiceType>PUROPRIO</est:ServiceType>
</est:Shipment>
<est:ShowAlternativeServicesIndicator>true</est:ShowAlternativeServicesIndicator>
<est:TotalWeight>
<est:Value>10</est:Value>
</est:TotalWeight>
<est:TotalPieces>
<est:Value>1</est:Value>
</est:TotalPieces>
</est:EstimateShipmentRequest>
  XML

  # Send the request using Savon
  response = client.call(:get_quick_estimate, message: { "p1:EstimateShipmentRequest" => xml_request },
                                             soap_header: { "wsse:UsernameToken" => { "wsse:Username" => Development_key,
                                                                                      "wsse:Password" => Password },
                                                            "wsu:Timestamp" => { "wsu:Created" => Time.now.utc.iso8601 } })

  xml_response = response.to_xml
  shipping_cost = xml_response.xpath("//est:TotalPrice").text.to_f

  puts "The estimated shipping cost is $#{shipping_cost}"
end
