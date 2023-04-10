require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db/db.sqlite')

# DB.extension :pagination

class Shipment < Sequel::Model
	one_to_many :parcels
	one_to_many :addresses

	def get_shipping_to()
		address = Address[self.shipping_to_address_id]
		return address
	end

	def get_shipping_from()
		address = Address[self.shipping_from_address_id]
		return address
	end

	def get_billed_to()
		address = Address[self.billed_address_id]
		return address
	end

	# def get_unassigned_items()
	# 	assigned_items = ParcelItem.where(parcel_id: Parcel.where(shipment_id: self.id).select(:id)).select_group(:item_id).sum(:quantity)
	# 	unassigned_items = []
	# 	items = Item.where(shipment_id: self.id).select(:id, :quantity)
	# 	items.each do |item|
	# 		assigned_quantity = assigned_items[item.id] || 0
	# 		unassigned_quantity = item.quantity - assigned_quantity
	# 		unassigned_items.push(unassigned_quantity) if unassigned_quantity > 0
	# 	end
	# 	return unassigned_items
	# end
end

class Parcel < Sequel::Model
	many_to_one :shipment
	many_to_many :items, join_table: :parcels_items, left_key: :parcel_id, right_key: :item_id
  
	def add_item(item, quantity)
	  # Check if the item already exists in the parcel
	  parcel_item = DB[:parcels_items].where(item_id: item.id).first
  
	  if parcel_item
		# If the item exists, update the quantity
		parcel_item.update(quantity: parcel_item[:quantity] + quantity)
	  else
		# If the item does not exist, create a new parcel item
		DB[:parcels_items].insert(item_id: item.id, parcel_id: self.id, quantity: quantity)
	  end
	end

	def remove_item(item, quantity)
	  # Check if the item exists in the parcel
	  parcel_item = DB[:parcels_items].where(item_id: item.id).first
  
	  if parcel_item
		# If the item exists, update the quantity
		parcel_item.update(quantity: parcel_item[:quantity] - quantity)
  
		# If the quantity is 0, delete the item from the parcel
		if parcel_item[:quantity] == 0
		  parcel_item.delete
		end
	  end
	end

	def get_items()
		items = DB[:parcels_items].where(parcel_id: self.id).select(:item_id, :quantity).all
		return items
	end
end

class Item < Sequel::Model
	many_to_many :parcels, join_table: :parcels_items, left_key: :item_id, right_key: :parcel_id
end

class Address < Sequel::Model
  one_to_one :shipment
end

class Token < Sequel::Model
  def before_save
	expires_at = DateTime.now + 0.0415
	self.token_expires_at = expires_at
	super
  end
end