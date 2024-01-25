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

ActiveRecord::Schema[7.1].define(version: 2024_01_24_223528) do
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
    t.boolean "exists_in_hathitrust", default: false, null: false
    t.boolean "exists_in_internet_archive", default: false, null: false
    t.boolean "exists_in_google", default: false, null: false
    t.string "ia_identifier"
    t.string "hathitrust_rights"
    t.string "hathitrust_access"
    t.string "source_path"
    t.text "raw_marcxml"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "cover_filename"
    t.index ["author"], name: "index_books_on_author"
    t.index ["bib_id"], name: "index_books_on_bib_id"
    t.index ["date"], name: "index_books_on_date"
    t.index ["exists_in_google"], name: "index_books_on_exists_in_google"
    t.index ["exists_in_hathitrust", "exists_in_internet_archive", "exists_in_google"], name: "index_books_on_service_existence_columns"
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
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

end
