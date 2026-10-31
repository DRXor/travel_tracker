# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_31_174232) do
  create_table "checklist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "done", default: false, null: false
    t.string "title", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_checklist_items_on_trip_id"
  end

  create_table "stops", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", null: false
    t.integer "trip_id", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id", "position"], name: "index_stops_on_trip_id_and_position"
    t.index ["trip_id"], name: "index_stops_on_trip_id"
  end

  create_table "trips", force: :cascade do |t|
    t.decimal "budget", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.string "destination"
    t.date "end_date"
    t.string "name"
    t.date "start_date"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "password_digest"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "checklist_items", "trips"
  add_foreign_key "stops", "trips"
  add_foreign_key "trips", "users"
end
