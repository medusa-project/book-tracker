# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_07_12_183425) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "books", force: :cascade do |t|
    t.integer "bib_id"
    t.string "oclc_number"
    t.string "obj_id"
    t.string "title"
    t.string "author"
    t.string "volume"
    t.string "date"
    t.string "language"
    t.string "subject"
    t.boolean "exists_in_hathitrust", default: false
    t.boolean "exists_in_internet_archive", default: false
    t.boolean "exists_in_google", default: false
    t.string "ia_identifier"
    t.string "hathitrust_rights"
    t.string "hathitrust_access"
    t.string "source_path"
    t.text "raw_marcxml"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author"], name: "index_books_on_author"
    t.index ["bib_id"], name: "index_books_on_bib_id"
    t.index ["date"], name: "index_books_on_date"
    t.index ["exists_in_google"], name: "index_books_on_exists_in_google"
    t.index ["exists_in_hathitrust"], name: "index_books_on_exists_in_hathitrust"
    t.index ["exists_in_internet_archive"], name: "index_books_on_exists_in_internet_archive"
    t.index ["hathitrust_access"], name: "index_books_on_hathitrust_access"
    t.index ["ia_identifier"], name: "index_books_on_ia_identifier"
    t.index ["obj_id"], name: "index_books_on_obj_id", unique: true
    t.index ["oclc_number"], name: "index_books_on_oclc_number"
    t.index ["title"], name: "index_books_on_title"
    t.index ["volume"], name: "index_books_on_volume"
  end

  create_table "tasks", force: :cascade do |t|
    t.string "name"
    t.decimal "service", precision: 1
    t.decimal "status", precision: 1
    t.float "percent_complete", default: 0.0
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username"
  end

end
