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

ActiveRecord::Schema.define(version: 2019_02_14_142355) do

  create_table "logs", force: :cascade do |t|
    t.string "job"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "target"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "project_extend_files", force: :cascade do |t|
    t.string "filename"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id"
    t.index ["project_id"], name: "index_project_extend_files_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "git_url"
    t.string "git_version"
    t.string "file_excludable"
    t.string "local_store_path"
    t.string "target_deploy_path"
    t.string "target_backup_path"
    t.string "task_pre_checkout"
    t.string "task_post_checkout"
    t.string "task_pre_deploy"
    t.string "task_post_deploy"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_included"
    t.integer "env_level"
  end

  create_table "publisher_servers", force: :cascade do |t|
    t.integer "server_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "project_id"
    t.index ["project_id"], name: "index_publisher_servers_on_project_id"
    t.index ["server_id"], name: "index_publisher_servers_on_server_id"
  end

  create_table "publishers", force: :cascade do |t|
    t.string "title"
    t.datetime "publish_time"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false
    t.index ["project_id"], name: "index_publishers_on_project_id"
  end

  create_table "servers", force: :cascade do |t|
    t.string "address"
    t.string "port"
    t.string "username"
    t.string "password"
    t.string "monitor_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rc_file_path"
    t.integer "env_level"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.string "auth_token"
    t.integer "level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
