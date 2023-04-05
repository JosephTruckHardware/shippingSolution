Sequel.migration do
	up do
		create_table(:parcels_items) do
			primary_key :id
            foreign_key :parcel_id, :parcels
            foreign_key :item_id, :items
			foreign_key :shipment_id, :shipments
            Integer :quantity
        end
	end

	down do
		drop_table(:parcels_items)
	end
end