# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140127222433) do

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "codename"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.string   "tagline"
    t.boolean  "visible"
    t.integer  "order",       :default => 0
  end

  create_table "categories_event_types", :id => false, :force => true do |t|
    t.integer "category_id"
    t.integer "event_type_id"
  end

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "iso_code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "event_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.text     "recipients"
    t.text     "program"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.text     "goal"
    t.integer  "duration"
    t.text     "faq"
    t.text     "materials"
    t.boolean  "include_in_catalog"
    t.text     "elevator_pitch"
    t.text     "learnings"
    t.text     "takeaways"
  end

  create_table "event_types_trainers", :id => false, :force => true do |t|
    t.integer "trainer_id"
    t.integer "event_type_id"
  end

  create_table "events", :force => true do |t|
    t.date     "date"
    t.string   "place"
    t.integer  "capacity"
    t.string   "city"
    t.integer  "country_id"
    t.integer  "trainer_id"
    t.string   "visibility_type",               :limit => 2
    t.decimal  "list_price",                                   :precision => 10, :scale => 2
    t.boolean  "list_price_plus_tax"
    t.integer  "list_price_2_pax_discount"
    t.integer  "list_price_3plus_pax_discount"
    t.decimal  "eb_price",                                     :precision => 10, :scale => 2
    t.date     "eb_end_date"
    t.boolean  "draft"
    t.boolean  "cancelled"
    t.datetime "created_at",                                                                                     :null => false
    t.datetime "updated_at",                                                                                     :null => false
    t.integer  "event_type_id"
    t.string   "registration_link"
    t.boolean  "is_sold_out"
    t.integer  "duration"
    t.time     "start_time"
    t.time     "end_time"
    t.boolean  "sepyme_enabled"
    t.boolean  "is_webinar",                                                                  :default => false
    t.string   "time_zone_name"
    t.text     "embedded_player"
    t.boolean  "notify_webinar_start",                                                        :default => false
    t.text     "twitter_embedded_search"
    t.boolean  "webinar_started",                                                             :default => false
    t.string   "currency_iso_code"
    t.string   "address"
    t.text     "custom_prices_email_text",      :limit => 255
    t.string   "monitor_email"
  end

  add_index "events", ["country_id"], :name => "index_events_on_country_id"
  add_index "events", ["trainer_id"], :name => "index_events_on_trainer_id"

  create_table "influence_zones", :force => true do |t|
    t.string   "zone_name"
    t.string   "tag_name"
    t.integer  "country_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "participants", :force => true do |t|
    t.string   "fname"
    t.string   "lname"
    t.string   "email"
    t.string   "phone"
    t.integer  "event_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "status"
    t.text     "notes"
    t.integer  "influence_zone_id"
  end

  add_index "participants", ["event_id"], :name => "index_participants_on_event_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "trainers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.text     "bio"
    t.string   "gravatar_email"
    t.string   "twitter_username"
    t.string   "linkedin_url"
    t.boolean  "is_kleerer"
    t.integer  "country_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
