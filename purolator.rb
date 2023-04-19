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
                                        <v2:EstimateShipmentRequest>
                                    <v2:Shipment>
                                <v2:SenderInformation>
                            <v2:Address>
                        <v2:City>Toronto</v2:City>
                    <v2:Province>ON</v2:Province>
                <v2:Country>CA</v2:Country>
            <v2:PostalCode>M5V2J4</v2:PostalCode>
        </v2:Address>
    </v2:SenderInformation>
<v2:ReceiverInformation>
<v2:Address>
<v2:City>Vancouver</v2:City>
<v2:Province>BC</v2:Province>
<v2:Country>CA</v2:Country>
<v2:PostalCode>V6B4N9</v2:PostalCode>
</v2:Address>
</v2:ReceiverInformation>
<v2:PackageInformation>
<v2:Weight>
<v2:Value>10</v2:Value>
</v2:Weight>
<v2:Dimensions>
<v2:Length>10</v2:Length>
<v2:Width>10</v2:Width>
<v2:Height>10</v2:Height>
</v2:Dimensions>
</v2:PackageInformation>
<v2:ServiceType>PUROPRIO</v2:ServiceType>
</v2:Shipment>
<v2:ShowAlternativeServicesIndicator>true</v2:ShowAlternativeServicesIndicator>
<v2:TotalWeight>
<v2:Value>10</v2:Value>
</v2:TotalWeight>
<v2:TotalPieces>
<v2:Value>1</v2:Value>
</v2:TotalPieces>
</v2:EstimateShipmentRequest>
  XML

  # Send the request using Savon
  response = client.call(:get_quick_estimate, message: { "p1:EstimateShipmentRequest" => xml_request },
                                              soap_header: { "wsse:UsernameToken" => { "wsse:Username" => Development_key,
                                                                                       "wsse:Password" => Password },
                                                             "wsu:Timestamp" => { "wsu:Created" => Time.now.utc.iso8601 } })

  xml_response = response.to_xml
  shipping_cost = xml_response.xpath("//v2:TotalPrice").text.to_f

  puts "The estimated shipping cost is $#{shipping_cost}"
end

def get_rate()
  rates = []
  total_weight = 100
  body = <<XML
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://purolator.com/pws/datatypes/v1">
  <SOAP-ENV:Header>
    <v2:RequestContext>
      <v2:Version>1.3</v2:Version>
      <v2:Language>en</v2:Language>
      <v2:GroupID>xxx</v2:GroupID>
      <v2:RequestReference>Rating Example</v2:RequestReference>
    </v2:RequestContext>
  </SOAP-ENV:Header>
  <SOAP-ENV:Body>
    <v2:GetQuickEstimateRequest>
      <v2:BillingAccountNumber></v2:BillingAccountNumber>
      <v2:SenderPostalCode>T1H5H3</v2:SenderPostalCode>
      <v2:ReceiverAddress>
        <v2:City>Lethbridge</v2:City>
        <v2:Province>AB</v2:Province>
        <v2:Country>CA</v2:Country>
        <v2:PostalCode>T0L0V2</v2:PostalCode>
      </v2:ReceiverAddress>
      <v2:PackageType>CustomerPackaging</v2:PackageType>
      <v2:TotalWeight>
        <v2:Value>10</v2:Value>
        <v2:WeightUnit>lb</v2:WeightUnit>
      </v2:TotalWeight>
    </v2:GetQuickEstimateRequest>
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
    env_namespace: 'http://schemas.xmlsoap.org/soap/envelope/',
    namespace: 'http://purolator.com/pws/datatypes/v2',
    namespace_identifier: 'v2',
    pretty_print_xml: true,
    log: true,
    log_level: :debug,
    soap_header: {
      "v2:RequestContext" => {
        "v2:Version" => "1.0",
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
                                                  "v2:City": "Lethbridge",
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
end