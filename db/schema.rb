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

ActiveRecord::Schema[8.1].define(version: 2026_10_11_000000) do
  create_table "cycle_subjects", force: :cascade do |t|
    t.integer "study_cycle_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "questions_count"
    t.decimal "points_per_question", precision: 8, scale: 2
    t.integer "knowledge_level", default: 3, null: false
    t.integer "configured_minutes"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["study_cycle_id", "position"], name: "index_cycle_subjects_on_study_cycle_id_and_position"
    t.index ["study_cycle_id"], name: "index_cycle_subjects_on_study_cycle_id"
  end

  create_table "study_cycles", force: :cascade do |t|
    t.integer "user_id"
    t.string "name", null: false
    t.integer "weekly_reference_minutes", default: 1440, null: false
    t.boolean "active", default: false, null: false
    t.string "seed_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "active"], name: "only_one_active_cycle_per_user", unique: true, where: "active = true"
    t.index ["user_id", "seed_key"], unique: true, where: "seed_key IS NOT NULL"
    t.index ["user_id"], name: "index_study_cycles_on_user_id"
  end

  create_table "study_sessions", force: :cascade do |t|
    t.integer "study_cycle_id", null: false
    t.integer "cycle_subject_id", null: false
    t.integer "minutes", null: false
    t.date "studied_on", null: false
    t.integer "sequence", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cycle_subject_id"], name: "index_study_sessions_on_cycle_subject_id"
    t.index ["study_cycle_id", "sequence"], name: "index_study_sessions_on_study_cycle_id_and_sequence", unique: true
    t.index ["study_cycle_id"], name: "index_study_sessions_on_study_cycle_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "cycle_subjects", "study_cycles"
  add_foreign_key "study_sessions", "cycle_subjects"
  add_foreign_key "study_sessions", "study_cycles"
  add_foreign_key "study_cycles", "users"
end
