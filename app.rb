require "./Fedex"
require "./models"
require "./shipment_pdf_generator"

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/weasyprint/lib")
require "weasyprint"

require "grover"
require "weasyprint"
require "sinatra"
require "sinatra/flash"
require "erb"
require "date"
require "json"

get "/" do
  @title = "Home"
  erb :index
end

get "/test" do
  create_new_shipment(1)
end

# NOT NEEDED??
# # Get item
# get "/items/:id" do
#   @item = Item[params[:id]]
#   erb :"items/_item", layout: false
# end

# Edit an item
# get "/items/:id/edit_modal" do
#   @item = Item[params[:id]]
#   erb :"items/_edit", locals: { item: @item }, layout: false
# end

# put "/items/:id" do
#   @item = Item[params[:id]]
#   @item.update(
#     weight: params[:weight],
#     weight_unit: params[:weight_unit],
#     description: params[:description],
#     sku: params[:sku],
#     hs_code: params[:hs_code],
#     value_amount: params[:value_amount],
#     value_currency: params[:value_currency],
#     origin_country: params[:origin_country],
#     order_id: params[:order_id],
#     single_item_per_parcel: params[:single_item_per_parcel] == "on",
#   )
#   @item.save
#   shipment = Shipment[@item.shipment_id]
#   redirect to("/shipments/" + shipment.id.to_s)
# end

# Edit an address
get "/addresses/:id/edit" do
  @address = Address.where(id: params[:id]).first
  erb :"addresses/_edit"
end

# Save edits to an address
#TODO MAKE THIS A PUT NOT POST
post "/addresses/:id" do
  address = Address.where(id: params[:id]).first
  address.update(
    address_type: params[:address_type],
    address_line_1: params[:address_line_1],
    address_line_2: params[:address_line_2],
    name: params[:name],
    city: params[:city],
    state_code: params[:state_code],
    country: params[:country],
    postal_code: params[:postal_code],
    phone_number: params[:phone_number],
    email: params[:email],
  )
  redirect back
end

# Show all shipments
get "/shipments" do
  @shipments = Shipment.all
  puts @shipments.inspect
  erb :"shipments/index"
end

# Get specific shipment
get "/shipments/:id" do
  @shipment = Shipment[params[:id]]
  @parcels = Parcel.where(shipment_id: @shipment.id).all
  @unassigned_items = @shipment.get_unassigned_items
  erb :"shipments/view"
end

# Edit a shipment
get "/shipments/:id/edit" do
  @shipment = Shipment[params[:id]]
  @shipping_from_address = Address[@shipment.shipping_from_address_id]
  @shipping_to_address = Address[@shipment.shipping_to_address_id]
  @billed_address = Address[@shipment.billed_address_id]
  erb :"shipments/edit"
end

# Save edits to a shipment
put "/shipments/:id" do
  shipment = Shipment[params[:id]]

  shipment.update(params[:shipment])

  shipment.order_id = params[:order_id]
  shipment.order_date = params[:order_date]
  shipment.status = params[:status]
  shipment.required_date = params[:required_date]
  shipment.tracking_number = params[:tracking_number]
  shipment.carrier_name = params[:carrier_name]
  shipment.service_name = params[:service_name]
  shipment.rate_response = params[:rate_response]
  shipment.shipped_at = params[:shipped_at]
  shipment.paid_by = params[:paid_by]
  shipment.metadata = params[:metadata]
  shipment.updated_by = params[:updated_by]

  # shipment.shipping_from_address.address_type = 'shipping_from'
  # shipment.shipping_from_address.address_line_1 = params[:shipping_from_address_line_1]
  # shipment.shipping_from_address.address_line_2 = params[:shipping_from_address_line_2]
  # shipment.shipping_from_address.name = params[:shipping_from_name]
  # shipment.shipping_from_address.city = params[:shipping_from_city]
  # shipment.shipping_from_address.state_code = params[:shipping_from_state_code]
  # shipment.shipping_from_address.country = params[:shipping_from_country]
  # shipment.shipping_from_address.postal_code = params[:shipping_from_postal_code]
  # shipment.shipping_from_address.phone_number = params[:shipping_from_phone_number]
  # shipment.shipping_from_address.email = params[:shipping_from_email]

  # shipment.shipping_to_address.address_type = 'shipping_to'
  # shipment.shipping_to_address.address_line_1 = params[:shipping_to_address_line_1]
  # shipment.shipping_to_address.address_line_2 = params[:shipping_to_address_line_2]
  # shipment.shipping_to_address.name = params[:shipping_to_name]
  # shipment.shipping_to_address.city = params[:shipping_to_city]
  # shipment.shipping_to_address.state_code = params[:shipping_to_state_code]
  # shipment.shipping_to_address.country = params[:shipping_to_country]
  # shipment.shipping_to_address.postal_code = params[:shipping_to_postal_code]
  # shipment.shipping_to_address.phone_number = params[:shipping_to_phone_number]
  # shipment.shipping_to_address.email = params[:shipping_to_email]

  # shipment.billed_address.address_type = 'billed'
  # shipment.billed_address.address_line_1 = params[:billed_address_line_1]
  # shipment.billed_address.address_line_2 = params[:billed_address_line_2]
  # shipment.billed_address.name = params[:billed_name]
  # shipment.billed_address.city = params[:billed_city]
  # shipment.billed_address.state_code = params[:billed_state_code]
  # shipment.billed_address.country = params[:billed_country]
  # shipment.billed_address.postal_code = params[:billed_postal_code]
  # shipment.billed_address.phone_number = params[:billed_phone_number]
  # shipment.billed_address.email = params[:billed_email]

  if shipment.valid?
    shipment.save
    redirect "/shipments"
  else
    @shipment = shipment
    @shipping_from_address = shipment.shipping_from_address
    @shipping_to_address = shipment.shipping_to_address
    @billed_address = shipment.billed_address
    erb :"shipments/edit"
  end
end

# Delete a shipment
delete "/shipments/:id" do
  shipment = Shipment[params[:id]]
  shipment.destroy
  redirect "/shipments"
end

# Add a package to a shipment
get "/shipments/:id/new_parcel" do
  @shipment = Shipment[params[:id]]
  erb :"parcels/_new", locals: { shipment: @shipment }, layout: false
end

# Save a new package
post "/shipments/:shipment_id/parcels" do
  @shipment = Shipment[params[:shipment_id]]
  parcel = @shipment.add_parcel(package_type: params[:package_type], length: params[:length], height: params[:height], width: params[:width], dimension_unit: params[:dimension_unit])

  if parcel.valid?
    parcel.save
    redirect "/shipments/#{params[:shipment_id]}"
  else
    # If there are validation errors, render the form again with error messages
    erb :"parcels/_new", layout: false
  end
end

# Save an edited package
put "/shipments/:shipment_id/parcels/:id" do
  parcel = Parcel[params[:id]]
  parcel.update(
    package_type: params[:package_type],
    weight: params[:weight],
    weight_unit: params[:weight_unit],
    length: params[:length],
    width: params[:width],
    height: params[:height],
    dimension_unit: params[:dimension_unit],
    tracking_number: params[:tracking_number],
  )
  parcel.save
  redirect "/shipments/" + parcel.shipment_id.to_s
end

# Delete a package
delete "/shipments/:shipment_id/parcels/:id" do
  parcel = Parcel[params[:id]]

  items = parcel.get_items

  puts items

  if items
    items.each do |item|
      item_obj = Item[item[:item_id]]
      parcel.remove_item(item_obj, item[:quantity])
    end
  end

  parcel.delete

  redirect "/shipments/" + parcel.shipment_id.to_s
end

# Add an item to a package
post "/shipments/:shipment_id/parcel/:id" do
  parcel = Parcel[params[:id]]
  selected_item = Item[params[:selected_item]]
  parcel.add_item(selected_item, params[:item_amount].to_i)
  parcel.save
  redirect "shipments/" + parcel.shipment_id.to_s
end

# Edit item in a package
get "/shipments/:shipment_id/parcels/:parcel_id/items/:id/edit" do
  @item = Item[params[:id]]
  erb :"items/_edit", layout: false
end

# Saved edited item in a package
put "/shipments/:shipment_id/parcels/:parcel_id/items/:id" do
  item = Item[params[:id]]
  item.update(
    name: params[:name],
    description: params[:description],
    value: params[:value],
    value_currency: params[:value_currency],
    weight: params[:weight],
    weight_unit: params[:weight_unit],
    quantity: params[:quantity],
    hs_tariff_number: params[:hs_tariff_number],
    origin_country: params[:origin_country],
  )
  item.save
  redirect "/shipments/" + item.parcel.shipment_id.to_s
end

# Remove an item from a package
delete "/shipments/:shipment_id/parcels/:parcel_id/items/:id" do
  item = Item[params[:id]]
  parcel = Parcel[params[:parcel_id]]
  parcel.remove_item_force(item)
  parcel.save
  redirect "/shipments/" + parcel.shipment_id.to_s
end

# TOOLS

# Merge shipments
get "/shipments/:shipment_id/merge_shipment/:merge_id" do
  puts "Merging shipment #{params[:shipment_id]} with shipment #{params[:merge_id]}"
  shipment = Shipment[params[:shipment_id]]
  merge_shipment = Shipment[params[:merge_id]]
  shipment.merge_shipment(merge_shipment)
  redirect "/shipments/" + shipment.id.to_s
end

# Get the invoice for a shipment
get "/shipments/:shipment_id/invoice" do
  @shipment = Shipment[params[:shipment_id]]
  html = erb :"documents/invoice", locals: { shipment: @shipment }, layout: false

  kit = WeasyPrint.new(html)

  content_type "application/pdf"

  pdf = kit.to_pdf

  pdf
  # options = { format: "A4", margin: "1cm" }
  # pdf = Grover.new(html).to_pdf

  # content_type 'application/pdf'
  # headers['Content-Disposition'] = 'inline'
  # pdf

  # pdf = Grover.new(shipment.invoice_html, format: "A4", margin: "0.5in")
  # pdf.to_pdf
end

post "/shipments/:shipment_id/parcel/:parcel_id/remove_item/:id" do
end

# Auto package all items into packages
get "/shipments/:id/auto_package_all" do
  shipment = Shipment[params[:id]]
  shipment.auto_package_all
  puts "Auto packaging all parcels"
end

# Get shipment postage rates
get "/shipments/:id/get_rates" do
  @rates = get_shipping_rates_international([params[:id]])
  puts @rates.inspect
  erb :"partials/_rates", layout: false
end

# Purchase a shipment label
get "shipments/:id/purchase_label" do
end

# Submit a shipment through webhook
post "/api/shipments" do
  request.body.rewind
  json_data = JSON.parse(request.body.read)

  shipment_data = json_data["shipment"]
  shipping_to_data = json_data["shipping_to"]
  billing_address_data = json_data["billing_address"]
  shipping_from_data = json_data["shipping_from"]
  items_data = json_data["items"]
  metadata = json_data["metadata"]
  metadata = JSON.generate(metadata)

  shipping_to_address = Address.new(shipping_to_data)
  shipping_to_address.save

  shipping_from_address = Address.new(shipping_from_data)
  shipping_from_address.save

  billing_address = Address.new(billing_address_data)
  billing_address.save

  shipment = Shipment.new(shipment_data)
  shipment.set(created_at: DateTime.now, updated_at: DateTime.now, status: "Pending")
  shipment.shipping_from_address_id = shipping_to_address.id
  shipment.shipping_to_address_id = shipping_from_address.id
  shipment.billed_address_id = billing_address.id
  shipment.metadata = metadata
  shipment.save

  items_data.each do |item_data|
    item = Item.new(item_data)
    item.shipment_id = shipment.id
    item.save
  end

  { shipment: shipment.inspect }.to_json
end
