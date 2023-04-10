Sequel.migration do
    up do
        create_table(:items) do
            primary_key :id
            foreign_key :shipment_id, :shipments, on_delete: :cascade
            Float :weight
            String :weight_unit
            String :description
            Integer :quantity, null: false, default: 0
            String :sku
            String :hs_code
            Float :value_amount
            String :value_currency
            String :origin_country
            String :order_id
            Boolean :single_item_per_parcel
        end
    end

    down do
        drop_table(:items)
    end
end
