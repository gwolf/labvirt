# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20081003222718) do

  create_table "disk_devs", :force => true do |t|
    t.string   "name"
    t.string   "path",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "disk_type_id",  :default => 1, :null => false
    t.integer  "media_type_id", :default => 1, :null => false
    t.integer  "profile_id"
    t.integer  "position",      :default => 1, :null => false
  end

  add_index "disk_devs", ["position", "profile_id"], :name => "index_disk_devs_on_position_and_profile_id", :unique => true
  add_index "disk_devs", ["name"], :name => "index_disk_devs_on_name", :unique => true

  create_table "disk_types", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "disk_types", ["name"], :name => "index_disk_types_on_name", :unique => true

  create_table "media_types", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "media_types", ["name"], :name => "index_media_types_on_name", :unique => true

  create_table "profiles", :force => true do |t|
    t.string   "name",                            :null => false
    t.string   "mac_base_addr",                   :null => false
    t.text     "descr"
    t.integer  "ram",           :default => 256,  :null => false
    t.string   "extra_params"
    t.integer  "instances",     :default => 1,    :null => false
    t.boolean  "active",        :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "profiles", ["mac_base_addr"], :name => "index_profiles_on_mac_base_addr", :unique => true
  add_index "profiles", ["name"], :name => "index_profiles_on_name", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"

  create_table "sys_confs", :force => true do |t|
    t.string   "key",        :null => false
    t.string   "descr"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sys_confs", ["key"], :name => "index_sys_confs_on_key", :unique => true

end
