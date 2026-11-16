class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string  :title, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :category, null: false, default: 4
      t.date    :spent_on, null: false

      t.timestamps
    end

    add_index :expenses, [:trip_id, :spent_on]
  end
end
