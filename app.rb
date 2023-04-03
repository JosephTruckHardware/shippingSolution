require './Fedex.rb'
require './models.rb'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/flash'
require 'erb'
require 'date'

get '/' do
    @title = "Home"
    erb :index
end

get '/test' do
    create_new_shipment(1)
end

post '/api/shipments' do
    request.body.rewind
    json_data = JSON.parse(request.body.read)

    shipment_data = json_data['shipment']
    shipping_to_data = json_data['shipping_to']
    billing_address_data = json_data['billing_address']
    shipping_from_data = json_data['shipping_from']
    items_data = json_data['items']

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
    shipment.save

    parcel = Parcel.new(shipment_id: shipment.id)
    parcel.save

    items_data.each do |item_data|
        item = Item.new(item_data)
        item.shipment_id = shipment.id
        item.save
    end

    { shipment: shipment.inspect}.to_json
end

get '/items/:id' do
    @item = Item[params[:id]]
    erb :'items/_item', layout: false
end


get '/items/:id/edit_modal' do
    @item = Item[params[:id]]
    erb :'items/_edit', locals: { item: @item }, layout: false
  end

put '/items/:id' do
    @item = Item[params[:id]]
    @item.update(
      weight: params[:weight],
      weight_unit: params[:weight_unit],
      description: params[:description],
      quantity: params[:quantity],
      sku: params[:sku],
      hs_code: params[:hs_code],
      value_amount: params[:value_amount],
      value_currency: params[:value_currency],
      origin_country: params[:origin_country],
      order_id: params[:order_id],
      single_item_per_parcel: params[:single_item_per_parcel] == "on"
    )
    parcel = Parcel[@item.parcel_id]
    shipment = Shipment[parcel.shipment_id]
    redirect to('/shipments/' + shipment.id.to_s)
end

get '/addresses/:id/edit' do
    @address = Address.where(id: params[:id]).first
    erb :'addresses/_edit'
end

post '/addresses/:id' do
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
      email: params[:email]
    )
    redirect back
end

get '/shipments' do
    @shipments = Shipment.all
    puts @shipments.inspect
    erb :'shipments/index'
end

get '/shipments/:id' do
    @shipment = Shipment[params[:id]]
    @parcels  = Parcel.where(shipment_id: @shipment.id).all
    erb :'shipments/view'
end

get '/shipments/:id/edit' do
    @shipment = Shipment[params[:id]]
    @shipping_from_address = Address[@shipment.shipping_from_address_id]
    @shipping_to_address = Address[@shipment.shipping_to_address_id]
    @billed_address = Address[@shipment.billed_address_id]
    erb :'shipments/edit'
end

put '/shipments/:id' do
    shipment = Shipment[params[:id]]
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
        redirect '/shipments'
    else
        @shipment = shipment
        @shipping_from_address = shipment.shipping_from_address
        @shipping_to_address = shipment.shipping_to_address
        @billed_address = shipment.billed_address
        erb :'shipments/edit'
    end
end

delete '/shipments/:id' do
    shipment = Shipment[params[:id]]
    shipment.destroy
    redirect '/shipments'
end

get '/shipments/:id/get_rates' do
    @rates = get_shipping_rates_international([params[:id]])
    puts @rates.inspect
    erb :'partials/_rates', layout: false
end

get 'shipments/:id/purchase_label' do

end