require "sqlite3"
require "sequel"

DB = Sequel.sqlite("db/db.sqlite")

# DB.extension :pagination

class Shipment < Sequel::Model
  one_to_many :parcels
  one_to_many :addresses

  def get_shipping_to
    Address[shipping_to_address_id]
  end

  def get_shipping_from
    Address[shipping_from_address_id]
  end

  def get_billed_to
    Address[billed_address_id]
  end

  def get_unassigned_items
    assigned_items = DB[:parcels_items].where(parcel_id: DB[:parcels].where(shipment_id: id).select(:id))
    unassigned_items = []
    items = Item.where(shipment_id: id).select(:id, :quantity)
    items.each do |item|
      assigned_quantity = assigned_items.where(item_id: item.id).sum(:quantity) || 0
      unassigned_quantity = item.quantity - assigned_quantity
      unassigned_items.push({item: item, quantity: unassigned_quantity}) if unassigned_quantity > 0
    end
    unassigned_items
  end

  def get_total_item_count
    DB[:parcels_items].where(parcel_id: DB[:parcels].where(shipment_id: id).select(:id)).sum(:quantity)
  end

  def get_total_weight
    weight = 0.00
    parcels_weight_dataset = parcels
    parcels_weight_dataset.each do |parcel|
      weight += parcel.weight
    end
    weight
  end

  def get_total_value
    value = 0.00
    parcels_value_dataset = parcels
    parcels_value_dataset.each do |parcel|
      value += parcel.get_total_value
    end
    value
  end
end

class ParcelsItem < Sequel::Model(:parcels_items)
  many_to_one :item
  many_to_one :parcel
end

class Parcel < Sequel::Model(:parcels)
  one_to_many :parcels_items
  many_to_one :shipment

  def get_total_value
    value = 0.00
    parcels_items_dataset.each do |parcel_item|
      value += parcel_item.item.value_amount * parcel_item.quantity
    end
    value
  end

  def add_item(item, quantity)
    parcel_item = parcels_items_dataset.where(item_id: item.id).first

    # If the item exists, update the quantity
    if parcel_item
      # Check if new quantity is greater than item quantity
      if parcel_item[:quantity] + quantity >= item.quantity
        parcel_item.update(quantity: parcel_item[:quantity] + quantity)
      end
    elsif item.quantity >= quantity
      ParcelsItem.create(item: item, parcel: self, quantity: quantity)
    # If the item does not exist, create a new parcel item
    else
      raise "Cannot add more items than exist in shipment"
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

  def remove_item_force(item)
    # Check if the item exists in the parcel
    parcel_item = parcels_items_dataset.where(item_id: item.id).first

    if parcel_item
      parcel_item.update(quantity: 0)
      parcel_item.delete
    else
      raise "Item not found in parcel"
    end
  end

  def get_items
    DB[:parcels_items].where(parcel_id: id).select(:item_id, :quantity).all
  end

  def get_items_detailed
    items = DB[:parcels_items].where(parcel_id: id).select(:item_id, :quantity).all
    items_detailed = []
    items.each do |item|
      item_detailed = Item[item[:item_id]].get_details
      item_detailed[0][:quantity] = item[:quantity]
      items_detailed.push(item_detailed[0])
    end
    items_detailed
  end
end

class Item < Sequel::Model
  many_to_many :parcels, join_table: :parcels_items, left_key: :item_id, right_key: :parcel_id

  def get_details
    DB[:items].where(id: id).all
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
