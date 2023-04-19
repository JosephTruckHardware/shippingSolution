require "savon"
require "net/http"
require "xmlsimple"
require "json"

Development_key = "7c4034699ff8406191794f1af15b8e57"
Password = "nWzJcm]}"
BillingAccountNumber = "9999999999"

def test()
  client = Savon.client(
    wsdl: "https://webservices.purolator.com/EWS/V2/Estimating/EstimatingService.asmx?wsdl",
    basic_auth: ["josephrwilms@gmail.com", Password],
  )

  response = client.call(:get_quick_estimate, message: { "p1:EstimateShipmentRequest" => "<p1:EstimateShipmentRequest></p1:EstimateShipmentRequest>" })

  response.body
end

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
                                        <ns1:EstimateShipmentRequest>
                                    <ns1:Shipment>
                                <ns1:SenderInformation>
                            <ns1:Address>
                        <ns1:City>Toronto</ns1:City>
                    <ns1:Province>ON</ns1:Province>
                <ns1:Country>CA</ns1:Country>
            <ns1:PostalCode>M5V2J4</ns1:PostalCode>
        </ns1:Address>
    </ns1:SenderInformation>
<ns1:ReceiverInformation>
<ns1:Address>
<ns1:City>Vancouver</ns1:City>
<ns1:Province>BC</ns1:Province>
<ns1:Country>CA</ns1:Country>
<ns1:PostalCode>V6B4N9</ns1:PostalCode>
</ns1:Address>
</ns1:ReceiverInformation>
<ns1:PackageInformation>
<ns1:Weight>
<ns1:Value>10</ns1:Value>
</ns1:Weight>
<ns1:Dimensions>
<ns1:Length>10</ns1:Length>
<ns1:Width>10</ns1:Width>
<ns1:Height>10</ns1:Height>
</ns1:Dimensions>
</ns1:PackageInformation>
<ns1:ServiceType>PUROPRIO</ns1:ServiceType>
</ns1:Shipment>
<ns1:ShowAlternativeServicesIndicator>true</ns1:ShowAlternativeServicesIndicator>
<ns1:TotalWeight>
<ns1:Value>10</ns1:Value>
</ns1:TotalWeight>
<ns1:TotalPieces>
<ns1:Value>1</ns1:Value>
</ns1:TotalPieces>
</ns1:EstimateShipmentRequest>
  XML

  # Send the request using Savon
  response = client.call(:get_quick_estimate, message: { "p1:EstimateShipmentRequest" => xml_request },
                                              soap_header: { "wsse:UsernameToken" => { "wsse:Username" => Development_key,
                                                                                       "wsse:Password" => Password },
                                                             "wsu:Timestamp" => { "wsu:Created" => Time.now.utc.iso8601 } })

  xml_response = response.to_xml
  shipping_cost = xml_response.xpath("//ns1:TotalPrice").text.to_f

  puts "The estimated shipping cost is $#{shipping_cost}"
end

def get_rate()
  rates = []
  total_weight = 100
  body = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://purolator.com/pws/datatypes/v1">
  <SOAP-ENV:Header>
    <ns1:RequestContext>
      <ns1:Version>1.3</ns1:Version>
      <ns1:Language>en</ns1:Language>
      <ns1:GroupID>xxx</ns1:GroupID>
      <ns1:RequestReference>Rating Example</ns1:RequestReference>
    </ns1:RequestContext>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <ns1:GetQuickEstimateRequest>
      <ns1:BillingAccountNumber></ns1:BillingAccountNumber>
      <ns1:SenderPostalCode>T1H5H3</ns1:SenderPostalCode>
      <ns1:ReceiverAddress>
        <ns1:City>Lethbridge</ns1:City>
        <ns1:Province>AB</ns1:Province>
        <ns1:Country>CA</ns1:Country>
        <ns1:PostalCode>T0L0V2</ns1:PostalCode>
      </ns1:ReceiverAddress>
      <ns1:PackageType>CustomerPackaging</ns1:PackageType>
      <ns1:TotalWeight>
        <ns1:Value>10</ns1:Value>
        <ns1:WeightUnit>lb</ns1:WeightUnit>
      </ns1:TotalWeight>
    </ns1:GetQuickEstimateRequest>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
XML

  http = Net::HTTP.new("devwebservices.purolator.com", 443)
  http.read_timeout = 60
  http.use_ssl = true

  req = Net::HTTP::Post.new("/PWS/V1/Estimating/EstimatingService.asmx")
  req.basic_auth("d3bab3e55d644f5aa161228f29418f45", "i9?|99VBO[rb%O")
  req.body = body
  req["Content-Type"] = "text/xml"
  req["SOAPAction"] = "http://purolator.com/pws/service/v1/GetQuickEstimate"
  res = http.request(req)

  if res.code.to_i < 400
    xml = XmlSimple.xml_in(res.body,
                           :forcearray => false)

    errors = xml["Body"]["GetQuickEstimateResponse"]["ResponseInformation"]["Errors"]
    estimates = xml["Body"]["GetQuickEstimateResponse"]["ShipmentEstimates"]["ShipmentEstimate"]

    if !errors.blank?
      errors = errors.map { |k, v| v["Description"] }
      raise Purolator::RateError, errors.join(", ")
    end

    if estimates.is_a?(Array)
      estimates.each do |r|
        next unless SERVICES[r["ServiceID"]]

        if r["ExpectedDeliveryDate"] and r["ExpectedDeliveryDate"].is_a?(String)
          d = Date.parse(r["ExpectedDeliveryDate"])
          days = (Date.today..d).select { |d| (1..5).include?(d.wday) }.size
          delivery = "#{days} business days"
        elsif r["ExpectedTransitDays"]
          delivery = "#{r["ExpectedTransitDays"].to_i} business days"
        end

        rates << {
          "id" => r["ServiceID"],
          "name" => SERVICES[r["ServiceID"]],
          "delivery" => delivery,
          "tracking" => true,
          "price" => r["TotalPrice"].to_f,
        }
      end
    end

    return rates
  else
    raise StandardError, "#{res.code} Error"
  end
end

def get_quick_estimate()
  client = Savon.client(
    wsdl: "https://devwebservices.purolator.com/EWS/V2/Estimating/EstimatingService.wsdl",
    basic_auth: [Development_key, Password],
    env_namespace: 'SOAP-ENV',
    namespace: 'http://purolator.com/pws/datatypes/v1',
    namespace_identifier: 'ns1',
    pretty_print_xml: true,
    log: true,
    log_level: :debug,
    soap_header: {
      "ns1:RequestContext" => {
        "ns1:Version" => "1.0",
        "ns1:Language" => "en",
        "ns1:GroupID" => "xxx",
        "ns1:RequestReference" => "Rating",
      },
    },
  )

  response = client.call(:get_quick_estimate, message: {
                                                "BillingAccountNumber": BillingAccountNumber,
                                                "SenderPostalCode": "T1H5H3",
                                                "ReceiverAddress": {
                                                  "City": "Lethbridge",
                                                  "Province": "AB",
                                                  "Country": "CA",
                                                  "PostalCode": "T0L0V2",
                                                },
                                                "PackageType": "CustomerPackaging",
                                                "TotalWeight": {
                                                  "Value": 10,
                                                  "WeightUnit": "lb",
                                                },
                                              })
end
