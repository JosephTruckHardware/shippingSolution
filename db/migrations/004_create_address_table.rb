Sequel.migration do
	up do
		create_table(:addresses) do
			primary_key :id
            String :address_type
            String :address_line_1
			String :address_line_2
			String :name
            String :city
            String :state_code
            String :country
            String :postal_code
            String :phone_number
			String :email
		end
	end

	down do
		drop_table(:addresses)
	end
end