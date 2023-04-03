Sequel.migration do
	up do
		create_table(:tokens) do
			primary_key :id
            String :token_number
            JSON :token
            DateTime :token_expires_at
		end
	end

	down do
		drop_table(:tokens)
	end
end