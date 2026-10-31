class CreateStops < ActiveRecord::Migration[8.1]
  def change
  create_table :stops do |t|
    t.references :trip, null: false, foreign_key: true
    t.string  :name, null: false
    t.integer :position, null: false
    t.timestamps
  end
  add_index :stops, [:trip_id, :position]
end
end
