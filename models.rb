require 'sqlite3'
require 'sequel'

DB = Sequel.sqlite('db/db.sqlite')

# DB.extension :pagination

class Shipment < Sequel::Model
    many_to_one :parcel
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

	# Make it so it recalculates weight when saved
	# def before_save
	# 	if self.

	# 	expires_at = DateTime.now + 0.0415
	# 	self.token_expires_at = expires_at
	# 	super
	# end
end

class Parcel < Sequel::Model
    many_to_one :shipment
	one_to_many :items
	
	def get_items()
		items = Item.where(parcel_id: self.id).all
		return items
	end

	def calculate_weight() 
		weight = 0.00
		items = get_items()
		items.each do |item|
			weight += item.weight
		end
		self.weight = weight
	end

	def total_items()
		item_count = 0
		items = get_items()
		items.each do |item|
			item_count += item.quantity
		end
		return item_count
	end

	def total_value()
		value = 0.00
		items = get_items()
		items.each do |item|
			value += item.value_amount
		end
		return value
	end

	# plugin :validation_helpers
	# def validate
	# 	super
	# 	validates_presence :package_type
	# 	validates_min_value 0.01, :weight, message: 'must be greater than 0'
	# end
end

class Item < Sequel::Model
	many_to_one :parcels
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