ActiveRecord::Schema.define(version: 1) do
  create_table :products, force: true do |t|
    t.string :name, null: false
    t.string :category
    t.decimal :price, precision: 10, scale: 2, default: 0
    t.integer :stock, default: 0
    t.timestamps
  end

  create_table :orders, force: true do |t|
    t.string :customer_name, null: false
    t.integer :product_id
    t.integer :quantity, default: 1
    t.decimal :total, precision: 10, scale: 2, default: 0
    t.string :status, default: "pending"
    t.timestamps
  end
end
