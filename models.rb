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

	def get_unassigned_items()
		assigned_items = DB[:parcels_items].where(parcel_id: DB[:parcels].where(shipment_id: self.id).select(:id))
		unassigned_items = []
		items = Item.where(shipment_id: self.id).select(:id, :quantity)
		items.each do |item|
			assigned_quantity = assigned_items.where(item_id: item.id).sum(:quantity) || 0
			unassigned_quantity = item.quantity - assigned_quantity
			unassigned_items.push({item: item, quantity: unassigned_quantity}) if unassigned_quantity > 0
		end
		return unassigned_items
	end
end

class ParcelsItem < Sequel::Model(:parcels_items)
	many_to_one :item
	many_to_one :parcel
end

class Parcel < Sequel::Model(:parcels)
	one_to_many :parcels_items
	many_to_one :shipment
  
	def add_item(item, quantity)
	  parcel_item = parcels_items_dataset.where(item_id: item.id).first
  
	  if parcel_item
		# If the item exists, update the quantity
		parcel_item.update(quantity: parcel_item[:quantity] + quantity)
	  else
		# If the item does not exist, create a new parcel item
		ParcelsItem.create(item: item, parcel: self, quantity: quantity)
	  end
	end

	def remove_item(item, quantity)
	  # Check if the item exists in the parcel
	  parcel_item = parcels_items_dataset.where(item_id: item.id).first
  
	  if parcel_item
		# If the item exists, update the quantity
		new_quantity = parcel_item[:quantity] - quantity
		if new_quantity >= 0
		  parcel_item.update(quantity: new_quantity)
	
		  # If the quantity is 0, delete the item from the parcel
		  if new_quantity == 0
			parcel_item.delete
		  end
		else
		  raise "Cannot remove more items than exist in the parcel"
		end
	  else
		raise "Item not found in parcel"
	  end
	end

	def get_items()
		items = DB[:parcels_items].where(parcel_id: self.id).select(:item_id, :quantity).all
		return items
	end

	def get_items_detailed()
		items = DB[:parcels_items].where(parcel_id: self.id).select(:item_id, :quantity).all
		items.each do |item|
			item[:item] = Item[item[:item_id]]
		end
		return items
	end
end

class Item < Sequel::Model
	many_to_many :parcels, join_table: :parcels_items, left_key: :item_id, right_key: :parcel_id

	def get_details()
		details = DB[:items_details].where(item_id: self.id).all
		return details
	end
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