Sequel.migration do
	up do
		create_table(:parcels_items) do
			primary_key :id
			Integer :quantity
			foreign_key :parcel_id, :parcels
			foreign_key :item_id, :items
        end
	end

	down do
		drop_table(:parcels_items)
	end
end