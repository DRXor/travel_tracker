class CreateChecklistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :checklist_items do |t|
      t.references :trip, null: false, foreign_key: true
      t.string  :title, null: false
      t.boolean :done, null: false, default: false
      t.timestamps
    end
  end
end
