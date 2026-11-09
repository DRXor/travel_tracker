class AddCoordinatesToStops < ActiveRecord::Migration[8.1]
  def change
    add_column :stops, :latitude,  :decimal, precision: 10, scale: 6
    add_column :stops, :longitude, :decimal, precision: 10, scale: 6
  end
end
