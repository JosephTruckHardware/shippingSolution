require "pdfkit"

class ShipmentPdfGenerator
  def initialize(shipment_id)
    @shipment = Shipment[shipment_id]
  end

  def generate_pdf
    pdfkit = PDFKit.new(html_for_shipment)
    pdfkit.to_file("#{@shipment.id}.pdf")
  end

  private

  def html_for_shipment
    <<~HTML
      <html>
        <body>
          <h1>Shipment Details</h1>
          <p>Order ID: #{order_id}</p>
          <p>Order Date: #{order_date}</p>
          <p>Status: #{status}</p>
          <p>Tracking Number: #{tracking_number}</p>
          <p>Carrier Name: #{carrier_name}</p>
          <p>Service Name: #{service_name}</p>
          <p>Shipping To:</p>
          <p>#{shipping_to_address}</p>
          <p>Shipping From:</p>
          <p>#{shipping_from_address}</p>
          <p>Billed To:</p>
          <p>#{billed_address}</p>
        </body>
      </html>
    HTML
  end

  def order_id
    @shipment.order_id
  end

  def order_date
    @shipment.order_date
  end

  def status
    @shipment.status
  end

  def tracking_number
    @shipment.tracking_number
  end

  def carrier_name
    @shipment.carrier_name
  end

  def service_name
    @shipment.service_name
  end

  def shipping_to_address
    address = Address[@shipment.shipping_to_address_id]
    "#{address.address_line_1}, #{address.address_line_2}, #{address.city}, #{address.state_code}, #{address.country}"
  end

  def shipping_from_address
    address = Address[@shipment.shipping_from_address_id]
    "#{address.address_line_1}, #{address.address_line_2}, #{address.city}, #{address.state_code}, #{address.country}"
  end

  def billed_address
    address = Address[@shipment.billed_address_id]
    "#{address.address_line_1}, #{address.address_line_2}, #{address.city}, #{address.state_code}, #{address.country}"
  end
end
