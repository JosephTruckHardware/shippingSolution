require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db/db.sqlite')

# DB.extension :pagination

class Shipment < Sequel::Model
    many_to_one :parcel_items
	one_to_many :records
	one_to_many :addresses

	def get_parcels()
		parcels = Parcel.where(shipment_id: self.id).all
		return parcels
	end

	def get_parcel_count()
		count = 0
		parcels = get_parcels()
		parcels.each do |parcel|
			count += 1
		end
		return count
	end

	def get_total_weight()
		weight = 0.00
		parcels = get_parcels()
		parcels.each do |parcel|
			parcel.calculate_weight
			weight += parcel.weight
		end
		return weight
	end

	def get_total_items() 
		item_count = 0
		parcels = get_parcels()
		parcels.each do |parcel|
			item_count += parcel.total_items()
		end
		return item_count
	end

	def get_total_value()
		value = 0.00
		parcels = get_parcels()
		parcels.each do |parcel|
			value += parcel.total_value()
		end
		return value
	end

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
		assigned_items = ParcelItem.where(parcel_id: Parcel.where(shipment_id: self.id).select(:id)).select_group(:item_id).sum(:quantity)
		unassigned_items = []
		items = Item.where(shipment_id: self.id).select(:id, :quantity)
		items.each do |item|
			assigned_quantity = assigned_items[item.id] || 0
			unassigned_quantity = item.quantity - assigned_quantity
			unassigned_items.push(unassigned_quantity) if unassigned_quantity > 0
		end
		return unassigned_items
	end
end

class Parcel < Sequel::Model
	one_to_many :parcel_items
		
	def get_items()
		items = Item.join(:parcel_items, parcel_id: self.id).all
		return items
	end

	def calculate_weight() 
		weight = 0.00
		items = get_items()
		items.each do |item|
			weight += item[:weight] * item[:quantity]
		end
		self.weight = weight
	end

	def total_items()
		item_count = 0
		items = get_items()
		items.each do |item|
			item_count += item[:quantity]
		end
		return item_count
	end

	def total_value()
		value = 0.00
		items = get_items()
		items.each do |item|
			value += item[:value_amount] * item[:quantity]
		end
		return value
	end
end

class Item < Sequel::Model
	one_to_many :parcel_items
	many_to_many :parcels, left_key: :item_id, right_key: :parcel_id, join_table: :parcel_items

	def get_parcels()
		parcels = Parcel.join(:parcel_items, item_id: self.id).all
		return parcels
	end
end

class Address < Sequel::Model
	many_to_one :shipment
end

class Token < Sequel::Model
	def before_save
		expires_at = DateTime.now + 0.0415
		self.token_expires_at = expires_at
		super
	end
end

class ParcelItem < Sequel::Model(:parcel_items)
	many_to_one :item
	one_to_one :parcel
end