Sequel.migration do
    up do
        create_table(:parcels) do
            primary_key :id
            # foreign_key :shipment_id, :shipments, on_delete: :cascade
            String :package_type
            Float :weight
            String :weight_unit
            Float :length
            Float :width
            Float :height
            String :dimension_unit
            String :tracking_number
        end
    end

    down do
        drop_table(:parcels)
    end
end