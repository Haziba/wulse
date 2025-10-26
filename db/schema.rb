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

ActiveRecord::Schema[8.0].define(version: 2025_10_26_171756) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "institution_stats", force: :cascade do |t|
    t.integer "institution_id", null: false
    t.date "date", null: false
    t.integer "total_documents"
    t.integer "active_staff"
    t.integer "storage_used"
    t.index ["institution_id"], name: "index_institution_stats_on_institution_id"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "branding_colour"
    t.integer "storage_used", limit: 8, default: 0, null: false
    t.integer "storage_total", default: 0
  end

  create_table "metadata", force: :cascade do |t|
    t.integer "oer_id", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oer_id", "key"], name: "index_metadata_on_oer_id_and_key", unique: true
    t.index ["oer_id"], name: "index_metadata_on_oer_id"
  end

  create_table "oers", force: :cascade do |t|
    t.integer "staff_id", null: false
    t.integer "institution_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "document_size", limit: 8, default: 0, null: false
    t.index ["document_size"], name: "index_oers_on_document_size"
    t.index ["institution_id"], name: "index_oers_on_institution_id"
    t.index ["staff_id"], name: "index_oers_on_staff_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.integer "institution_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.datetime "last_login"
    t.string "title"
    t.index ["institution_id"], name: "index_staffs_on_institution_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "institution_stats", "institutions"
  add_foreign_key "metadata", "oers", on_delete: :cascade
  add_foreign_key "oers", "institutions"
  add_foreign_key "oers", "staffs"
  add_foreign_key "staffs", "institutions"
end
