class RemoveDuplicateColumnsFromTrips < ActiveRecord::Migration[8.1]
  def change
    remove_column :trips, :title, :string
    remove_column :trips, :notes, :text
  end
end
