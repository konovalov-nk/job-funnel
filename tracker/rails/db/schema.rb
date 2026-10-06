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

ActiveRecord::Schema[8.1].define(version: 2026_05_31_094339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "fetch_runs", force: :cascade do |t|
    t.string "adapter"
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "retry_count"
    t.bigint "source_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_fetch_runs_on_source_id"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sources", force: :cascade do |t|
    t.string "adapter"
    t.string "auth_mode"
    t.string "base_url"
    t.datetime "created_at", null: false
    t.boolean "enabled"
    t.string "name"
    t.string "source_type"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "fetch_runs", "sources"
end
