Sequel.migration do
	up do
		create_table(:parcel_items) do
			primary_key :id
            foreign_key :parcel_id, :parcels
            foreign_key :item_id, :items
            Integer :quantity, default: 1 # add a quantity column
        end
	end

	down do
		drop_table(:parcel_items)
	end
end