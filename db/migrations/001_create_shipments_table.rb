Sequel.migration do
  up do
    create_table(:shipments) do
      primary_key :id
      String :order_id
      DateTime :order_date
      String :status
      foreign_key :shipping_to_address_id, :addresses, on_delete: :cascade
      foreign_key :shipping_from_address_id, :addresses, on_delete: :cascade
      foreign_key :billed_address_id, :addresses, on_delete: :cascade
      DateTime :created_at
      DateTime :updated_at
      DateTime :required_date
      String :tracking_number
      String :carrier_name
      String :service_name
      JSON :rate_response
      DateTime :shipped_at
      String :paid_by
      JSON :metadata
      String :updated_by
    end
  end

  down do
    drop_table(:shipments)
  end
end
