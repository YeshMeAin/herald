ActiveRecord::Schema.define(version: 1) do
  create_table :widgets, force: true do |t|
    t.string :name, null: false
    t.integer :quantity, default: 0
    t.timestamps
  end
end
