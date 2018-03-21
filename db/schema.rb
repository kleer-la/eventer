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

ActiveRecord::Schema.define(:version => 20180321014100) do

  create_table "campaign_sources", :force => true do |t|
    t.string   "codename"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "campaign_views", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "event_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.integer  "campaign_source_id"
    t.string   "element_viewed"
  end

  create_table "campaigns", :force => true do |t|
    t.string   "codename"
    t.text     "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "codename"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.string   "tagline"
    t.boolean  "visible"
    t.integer  "order",                         :default => 0
    t.string   "name_en"
    t.text     "description_en", :limit => 255
    t.string   "tagline_en"
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

  create_table "crm_push_transaction_items", :force => true do |t|
    t.integer  "crm_push_transaction_id"
    t.integer  "participant_id"
    t.text     "log"
    t.string   "result"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "crm_push_transactions", :force => true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
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
    t.datetime "created_at",                                                              :null => false
    t.datetime "updated_at",                                                              :null => false
    t.text     "goal"
    t.integer  "duration"
    t.text     "faq"
    t.text     "materials"
    t.boolean  "include_in_catalog"
    t.text     "elevator_pitch"
    t.text     "learnings"
    t.text     "takeaways"
    t.string   "tag_name"
    t.boolean  "csd_eligible"
    t.decimal  "average_rating",         :precision => 4, :scale => 2
    t.integer  "net_promoter_score"
    t.integer  "surveyed_count"
    t.integer  "promoter_count"
    t.string   "subtitle"
    t.text     "cancellation_policy"
    t.boolean  "is_kleer_certification",                               :default => false
    t.string   "kleer_cert_seal_image"
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
    t.string   "visibility_type",             :limit => 2
    t.decimal  "list_price",                                 :precision => 10, :scale => 2
    t.decimal  "eb_price",                                   :precision => 10, :scale => 2
    t.date     "eb_end_date"
    t.boolean  "draft"
    t.boolean  "cancelled"
    t.datetime "created_at",                                                                                   :null => false
    t.datetime "updated_at",                                                                                   :null => false
    t.integer  "event_type_id"
    t.string   "registration_link"
    t.boolean  "is_sold_out"
    t.integer  "duration"
    t.time     "start_time"
    t.time     "end_time"
    t.boolean  "sepyme_enabled"
    t.string   "time_zone_name"
    t.text     "embedded_player"
    t.boolean  "notify_webinar_start",                                                      :default => false
    t.text     "twitter_embedded_search"
    t.boolean  "webinar_started",                                                           :default => false
    t.string   "currency_iso_code"
    t.string   "address"
    t.text     "custom_prices_email_text",    :limit => 255
    t.string   "monitor_email"
    t.text     "specific_conditions"
    t.boolean  "should_welcome_email",                                                      :default => true
    t.boolean  "should_ask_for_referer_code",                                               :default => false
    t.decimal  "couples_eb_price",                           :precision => 10, :scale => 2
    t.decimal  "business_price",                             :precision => 10, :scale => 2
    t.decimal  "business_eb_price",                          :precision => 10, :scale => 2
    t.decimal  "enterprise_6plus_price",                     :precision => 10, :scale => 2
    t.decimal  "enterprise_11plus_price",                    :precision => 10, :scale => 2
    t.date     "finish_date"
    t.boolean  "show_pricing",                                                              :default => false
    t.decimal  "average_rating",                             :precision => 4,  :scale => 2
    t.integer  "net_promoter_score"
    t.string   "mode",                        :limit => 2
    t.integer  "trainer2_id"
    t.text     "extra_script"
    t.integer  "trainer3_id"
    t.boolean  "mailchimp_workflow"
    t.string   "mailchimp_workflow_call"
    t.string   "banner_text"
    t.string   "banner_type"
    t.date     "registration_ends"
    t.text     "cancellation_policy"
    t.string   "specific_subtitle"
    t.boolean  "enable_online_payment",                                                     :default => false
    t.string   "online_course_codename"
    t.string   "online_cohort_codename"
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
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
    t.string   "status"
    t.text     "notes"
    t.integer  "influence_zone_id"
    t.string   "referer_code"
    t.string   "verification_code"
    t.integer  "event_rating"
    t.integer  "trainer_rating"
    t.text     "testimony"
    t.integer  "promoter_score"
    t.integer  "trainer2_rating"
    t.string   "xero_invoice_number"
    t.string   "xero_invoice_reference"
    t.decimal  "xero_invoice_amount",    :precision => 10, :scale => 2
    t.boolean  "is_payed",                                              :default => false
    t.string   "payment_type"
    t.integer  "campaign_id"
    t.integer  "campaign_source_id"
  end

  add_index "participants", ["event_id"], :name => "index_participants_on_event_id"

  create_table "ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "global_nps"
    t.integer  "global_nps_count"
    t.decimal  "global_trainer_rating",       :precision => 4, :scale => 2
    t.integer  "global_trainer_rating_count"
    t.decimal  "global_event_rating",         :precision => 4, :scale => 2
    t.integer  "global_event_rating_count"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
  end

  add_index "ratings", ["user_id"], :name => "index_ratings_on_user_id"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "settings", :force => true do |t|
    t.string   "key"
    t.text     "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "trainers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.text     "bio"
    t.string   "gravatar_email"
    t.string   "twitter_username"
    t.string   "linkedin_url"
    t.boolean  "is_kleerer"
    t.integer  "country_id"
    t.string   "tag_name"
    t.string   "signature_image"
    t.string   "signature_credentials"
    t.decimal  "average_rating",        :precision => 4, :scale => 2
    t.integer  "net_promoter_score"
    t.integer  "surveyed_count"
    t.integer  "promoter_count"
    t.text     "bio_en"
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
