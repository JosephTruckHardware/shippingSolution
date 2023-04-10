require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db/db.sqlite')

# DB.extension :pagination

class Shipment < Sequel::Model
	one_to_many :parcels_items
	one_to_many :addresses
	one_to_many :parcels
	one_to_many :items

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

class ParcelItem < Sequel::Model(:parcels_items)
  many_to_one :item
  many_to_one :parcel

  def add_item(item, quantity)
	parcel_item = ParcelItem.find_or_create(parcel_id: self.id, item_id: item.id)
	parcel_item.quantity = quantity
	parcel_item.save
  end
end

class Parcel < Sequel::Model
  many_to_many :items, join_table: :parcels_items

  def add_item(item)
	parcels_items_dataset.insert(parcel_id: id, item_id: item.id)
  end
end

class Item < Sequel::Model
  many_to_many :parcels, join_table: :parcels_items

	# one_to_many :parcel_items
	# many_to_many :parcels, left_key: :item_id, right_key: :parcel_id, join_table: :parcel_items

	# def get_parcels()
	# 	parcels = Parcel.join(:parcel_items, item_id: self.id).all
	# 	return parcels
	# end
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