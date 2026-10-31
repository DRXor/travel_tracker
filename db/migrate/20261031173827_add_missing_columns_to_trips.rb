class AddMissingColumnsToTrips < ActiveRecord::Migration[8.1]
  def change
  add_column :trips, :title,       :string  unless column_exists?(:trips, :title)
  add_column :trips, :destination, :string  unless column_exists?(:trips, :destination)
  add_column :trips, :start_date,  :date    unless column_exists?(:trips, :start_date)
  add_column :trips, :end_date,    :date    unless column_exists?(:trips, :end_date)
  add_column :trips, :budget,      :decimal, precision: 10, scale: 2 unless column_exists?(:trips, :budget)
  add_column :trips, :notes,       :text    unless column_exists?(:trips, :notes)
  add_column :trips, :status,      :integer, null: false, default: 0 unless column_exists?(:trips, :status)
  end
end
