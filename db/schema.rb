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

ActiveRecord::Schema[8.1].define(version: 2026_05_26_200000) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "answers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position"
    t.integer "question_id", null: false
    t.string "text"
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answers_on_question_id"
  end

  create_table "articles", force: :cascade do |t|
    t.text "body"
    t.integer "category_id"
    t.string "cover"
    t.datetime "created_at", precision: nil, null: false
    t.string "description"
    t.string "header"
    t.integer "industry"
    t.integer "lang", default: 0, null: false
    t.boolean "noindex", default: false, null: false
    t.boolean "published", default: false
    t.boolean "selected", default: false, null: false
    t.string "slug", null: false
    t.datetime "substantive_change_at"
    t.string "tabtitle"
    t.string "title", null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["substantive_change_at"], name: "index_articles_on_substantive_change_at"
  end

  create_table "articles_trainers", id: false, force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "trainer_id", null: false
    t.index ["article_id", "trainer_id"], name: "index_articles_trainers_on_article_id_and_trainer_id"
  end

  create_table "assessments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "language", default: "es", null: false
    t.integer "resource_id"
    t.boolean "rule_based", default: false, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["resource_id"], name: "index_assessments_on_resource_id"
  end

  create_table "authorships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "resource_id", null: false
    t.integer "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id", "trainer_id"], name: "index_authorships_on_resource_id_and_trainer_id", unique: true
    t.index ["resource_id"], name: "index_authorships_on_resource_id"
    t.index ["trainer_id"], name: "index_authorships_on_trainer_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.string "google_event_id"
    t.text "notes"
    t.json "qualifying_answers"
    t.integer "service_area_id"
    t.datetime "starts_at", null: false
    t.string "status", default: "confirmed"
    t.integer "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.string "visitor_company"
    t.string "visitor_email", null: false
    t.string "visitor_name", null: false
    t.index ["service_area_id"], name: "index_bookings_on_service_area_id"
    t.index ["trainer_id"], name: "index_bookings_on_trainer_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "codename"
    t.datetime "created_at", precision: nil
    t.text "description"
    t.text "description_en"
    t.string "name"
    t.string "name_en"
    t.integer "order", default: 0
    t.string "tagline"
    t.string "tagline_en"
    t.datetime "updated_at", precision: nil
    t.boolean "visible"
  end

  create_table "categories_event_types", id: false, force: :cascade do |t|
    t.integer "category_id"
    t.integer "event_type_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.integer "assessment_id"
    t.datetime "assessment_report_generated_at"
    t.text "assessment_report_html"
    t.string "assessment_report_url"
    t.string "company"
    t.boolean "content_updates_opt_in", default: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.json "form_data", default: {}, null: false
    t.string "name"
    t.boolean "newsletter_added", default: false, null: false
    t.boolean "newsletter_opt_in", default: false
    t.datetime "processed_at"
    t.string "resource_slug"
    t.integer "status", default: 0
    t.integer "trigger_type", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_contacts_on_assessment_id"
    t.index ["resource_slug"], name: "index_contacts_on_resource_slug"
  end

  create_table "countries", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "iso_code"
    t.string "name"
    t.datetime "updated_at", precision: nil
  end

  create_table "coupons", force: :cascade do |t|
    t.boolean "active"
    t.decimal "amount_off", precision: 10, scale: 2
    t.string "code"
    t.integer "coupon_type"
    t.datetime "created_at", null: false
    t.boolean "display"
    t.date "expires_on"
    t.string "icon"
    t.string "internal_name"
    t.decimal "percent_off", precision: 5, scale: 2
    t.datetime "updated_at", null: false
  end

  create_table "coupons_event_types", id: false, force: :cascade do |t|
    t.integer "coupon_id", null: false
    t.datetime "created_at", null: false
    t.integer "event_type_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type_id", "coupon_id"], name: "index_coupons_event_types_on_event_type_id_and_coupon_id"
  end

  create_table "crm_push_transaction_items", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "crm_push_transaction_id"
    t.text "log"
    t.integer "participant_id"
    t.string "result"
    t.datetime "updated_at", precision: nil
  end

  create_table "crm_push_transactions", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "event_id"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0
    t.datetime "created_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "handler"
    t.text "last_error"
    t.datetime "locked_at", precision: nil
    t.string "locked_by"
    t.integer "priority", default: 0
    t.string "queue"
    t.datetime "run_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "episodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "episode"
    t.integer "podcast_id"
    t.date "published_at"
    t.integer "season"
    t.string "spotify_url"
    t.string "thumbnail_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "youtube_url"
    t.index ["podcast_id"], name: "index_episodes_on_podcast_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.decimal "average_rating", precision: 4, scale: 2
    t.string "brochure"
    t.text "cancellation_policy"
    t.integer "canonical_id"
    t.string "cover"
    t.datetime "created_at", precision: nil
    t.boolean "csd_eligible"
    t.boolean "deleted", default: false, null: false
    t.text "description"
    t.integer "duration"
    t.text "elevator_pitch"
    t.integer "external_id"
    t.string "external_site_url"
    t.text "extra_script"
    t.text "faq"
    t.text "goal"
    t.boolean "include_in_catalog"
    t.boolean "is_kleer_certification", default: false
    t.string "kleer_cert_seal_image"
    t.integer "lang", default: 0, null: false
    t.text "learnings"
    t.text "materials"
    t.string "name"
    t.integer "net_promoter_score"
    t.boolean "new_version", default: false, null: false
    t.boolean "noindex", default: false, null: false
    t.integer "ordering", default: 100
    t.integer "platform", default: 0
    t.text "program"
    t.integer "promoter_count"
    t.text "recipients"
    t.string "seo_title"
    t.string "side_image"
    t.string "subtitle"
    t.integer "surveyed_count"
    t.string "tag_name"
    t.text "takeaways"
    t.datetime "updated_at", precision: nil
    t.index ["canonical_id"], name: "index_event_types_on_canonical_id"
  end

  create_table "event_types_trainers", id: false, force: :cascade do |t|
    t.integer "event_type_id"
    t.integer "trainer_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "address"
    t.decimal "average_rating", precision: 4, scale: 2
    t.text "banner_text"
    t.string "banner_type"
    t.decimal "business_eb_price", precision: 10, scale: 2
    t.decimal "business_price", precision: 10, scale: 2
    t.text "cancellation_policy"
    t.boolean "cancelled"
    t.integer "capacity"
    t.string "city"
    t.integer "country_id"
    t.decimal "couples_eb_price", precision: 10, scale: 2
    t.datetime "created_at", precision: nil
    t.string "currency_iso_code"
    t.text "custom_prices_email_text"
    t.date "date"
    t.boolean "draft"
    t.integer "duration"
    t.date "eb_end_date"
    t.decimal "eb_price", precision: 10, scale: 2
    t.text "embedded_player"
    t.boolean "enable_online_payment", default: false
    t.time "end_time"
    t.decimal "enterprise_11plus_price", precision: 10, scale: 2
    t.decimal "enterprise_6plus_price", precision: 10, scale: 2
    t.integer "event_type_id"
    t.text "extra_script"
    t.date "finish_date"
    t.boolean "is_sold_out"
    t.decimal "list_price", precision: 10, scale: 2
    t.boolean "mailchimp_workflow"
    t.string "mailchimp_workflow_call"
    t.boolean "mailchimp_workflow_for_warmup"
    t.string "mailchimp_workflow_for_warmup_call"
    t.string "mode", limit: 2
    t.string "monitor_email"
    t.integer "net_promoter_score"
    t.boolean "notify_webinar_start", default: false
    t.string "online_cohort_codename"
    t.string "online_course_codename"
    t.string "place"
    t.date "registration_ends"
    t.string "registration_link"
    t.boolean "sepyme_enabled"
    t.boolean "should_ask_for_referer_code", default: false
    t.boolean "should_welcome_email", default: true
    t.boolean "show_pricing", default: false
    t.text "specific_conditions"
    t.string "specific_subtitle"
    t.time "start_time"
    t.string "time_zone_name"
    t.integer "trainer2_id"
    t.integer "trainer3_id"
    t.integer "trainer_id"
    t.text "twitter_embedded_search"
    t.datetime "updated_at", precision: nil
    t.string "visibility_type", limit: 2
    t.boolean "webinar_started", default: false
    t.index ["country_id"], name: "index_events_on_country_id"
    t.index ["trainer_id"], name: "index_events_on_trainer_id"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "illustrations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "resource_id", null: false
    t.integer "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id"], name: "index_illustrations_on_resource_id"
    t.index ["trainer_id"], name: "index_illustrations_on_trainer_id"
  end

  create_table "influence_zones", force: :cascade do |t|
    t.integer "country_id"
    t.datetime "created_at", precision: nil
    t.string "tag_name"
    t.datetime "updated_at", precision: nil
    t.string "zone_name"
  end

  create_table "logs", force: :cascade do |t|
    t.integer "area"
    t.datetime "created_at", precision: nil, null: false
    t.text "details"
    t.integer "level"
    t.string "message"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "mail_templates", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "cc"
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "delivery_schedule", default: 0
    t.string "identifier", null: false
    t.integer "lang", default: 0, null: false
    t.string "subject", null: false
    t.string "to", null: false
    t.integer "trigger_type", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_schedule"], name: "index_mail_templates_on_delivery_schedule"
    t.index ["identifier"], name: "index_mail_templates_on_identifier", unique: true
    t.index ["trigger_type"], name: "index_mail_templates_on_trigger_type"
  end

  create_table "news", force: :cascade do |t|
    t.string "audio"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "event_date"
    t.string "img"
    t.integer "lang", default: 0, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "video"
    t.boolean "visible", default: true, null: false
    t.string "where"
  end

  create_table "news_trainers", id: false, force: :cascade do |t|
    t.integer "news_id", null: false
    t.integer "trainer_id", null: false
    t.index ["news_id", "trainer_id"], name: "index_news_trainers_on_news_id_and_trainer_id"
    t.index ["trainer_id", "news_id"], name: "index_news_trainers_on_trainer_id_and_news_id"
  end

  create_table "oauth_tokens", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.string "issuer"
    t.string "tenant_id"
    t.string "token_set"
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "pages", force: :cascade do |t|
    t.string "canonical"
    t.string "cover"
    t.datetime "created_at", null: false
    t.integer "lang"
    t.string "name"
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug", "lang"], name: "index_pages_on_slug_and_lang", unique: true
  end

  create_table "participants", force: :cascade do |t|
    t.string "address"
    t.string "company_name"
    t.datetime "created_at", precision: nil
    t.string "email"
    t.integer "event_id"
    t.integer "event_rating"
    t.string "fname"
    t.string "id_number"
    t.integer "influence_zone_id"
    t.string "invoice_id"
    t.boolean "is_payed", default: false
    t.string "konline_po_number"
    t.string "lname"
    t.text "notes"
    t.string "online_invoice_url"
    t.text "pay_notes"
    t.string "payment_type"
    t.string "phone"
    t.string "photo_url"
    t.string "profile_url"
    t.integer "promoter_score"
    t.integer "quantity", default: 1, null: false
    t.string "referer_code"
    t.boolean "selected", default: false, null: false
    t.string "status"
    t.text "testimony"
    t.integer "trainer2_rating"
    t.integer "trainer_rating"
    t.datetime "updated_at", precision: nil
    t.string "verification_code"
    t.decimal "xero_invoice_amount", precision: 10, scale: 2
    t.string "xero_invoice_number"
    t.string "xero_invoice_reference"
    t.index ["event_id"], name: "index_participants_on_event_id"
  end

  create_table "podcasts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "spotify_url"
    t.string "thumbnail_url"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "youtube_url"
  end

  create_table "question_groups", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_question_groups_on_assessment_id"
  end

  create_table "questions", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.integer "position"
    t.integer "question_group_id"
    t.string "question_type", default: "linear_scale"
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_questions_on_assessment_id"
    t.index ["question_group_id"], name: "index_questions_on_question_group_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.decimal "global_event_rating", precision: 4, scale: 2
    t.integer "global_event_rating_count"
    t.integer "global_nps"
    t.integer "global_nps_count"
    t.decimal "global_trainer_rating", precision: 4, scale: 2
    t.integer "global_trainer_rating_count"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "recommended_contents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "relevance_order", default: 50, null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.integer "target_id", null: false
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id"], name: "index_recommended_contents_on_source"
    t.index ["target_type", "target_id"], name: "index_recommended_contents_on_target"
  end

  create_table "resources", force: :cascade do |t|
    t.string "buyit_en"
    t.string "buyit_es"
    t.integer "category_id"
    t.text "comments_en"
    t.text "comments_es"
    t.string "cover_en"
    t.string "cover_es"
    t.datetime "created_at", null: false
    t.text "description_en"
    t.text "description_es"
    t.boolean "downloadable"
    t.integer "format"
    t.string "getit_en"
    t.string "getit_es"
    t.string "landing_en"
    t.string "landing_es"
    t.text "long_description_en"
    t.text "long_description_es"
    t.string "preview_en"
    t.string "preview_es"
    t.boolean "published"
    t.string "seo_description_en"
    t.string "seo_description_es"
    t.string "share_link_en"
    t.string "share_link_es"
    t.string "share_text_en"
    t.string "share_text_es"
    t.string "slug", null: false
    t.string "tabtitle_en"
    t.string "tabtitle_es"
    t.string "tags_en"
    t.string "tags_es"
    t.string "title_en"
    t.string "title_es"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_resources_on_category_id"
    t.index ["slug"], name: "index_resources_on_slug", unique: true
  end

  create_table "responses", force: :cascade do |t|
    t.integer "answer_id"
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.text "text_response"
    t.datetime "updated_at", null: false
    t.index ["answer_id"], name: "index_responses_on_answer_id"
    t.index ["contact_id"], name: "index_responses_on_contact_id"
    t.index ["question_id"], name: "index_responses_on_question_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "name"
    t.datetime "updated_at", precision: nil
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "rules", force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.text "conditions", default: "{}", null: false
    t.datetime "created_at", null: false
    t.text "diagnostic_text", null: false
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id", "position"], name: "index_rules_on_assessment_id_and_position", unique: true
    t.index ["assessment_id"], name: "index_rules_on_assessment_id"
  end

  create_table "sections", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "cta_text"
    t.string "cta_url"
    t.integer "page_id"
    t.integer "position"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["page_id"], name: "index_sections_on_page_id"
    t.index ["slug", "page_id"], name: "index_sections_on_slug_and_page_id", unique: true
  end

  create_table "service_areas", force: :cascade do |t|
    t.text "abstract"
    t.datetime "created_at", null: false
    t.string "icon"
    t.boolean "is_training_program", default: false, null: false
    t.integer "lang"
    t.string "name"
    t.integer "ordering"
    t.string "primary_color"
    t.string "primary_font_color", default: "#000000"
    t.text "recommended_way_details"
    t.string "recommended_way_note"
    t.text "recommended_way_summary"
    t.string "recommended_way_title"
    t.string "secondary_color"
    t.string "secondary_font_color", default: "#000000"
    t.string "seo_description"
    t.string "seo_title"
    t.string "side_image"
    t.string "slug"
    t.string "target_title"
    t.datetime "updated_at", null: false
    t.string "value_proposition_title"
    t.boolean "visible"
    t.index ["slug"], name: "index_service_areas_on_slug", unique: true
  end

  create_table "service_areas_trainers", id: false, force: :cascade do |t|
    t.integer "service_area_id"
    t.integer "trainer_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "brochure"
    t.text "card_description"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "ordering"
    t.string "pricing"
    t.text "recommended_way_details"
    t.string "recommended_way_note"
    t.text "recommended_way_summary"
    t.string "recommended_way_title"
    t.text "seo_description"
    t.string "seo_title"
    t.integer "service_area_id"
    t.string "side_image"
    t.string "slug"
    t.string "subtitle"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: false, null: false
    t.index ["service_area_id"], name: "index_services_on_service_area_id"
    t.index ["slug"], name: "index_services_on_slug", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "key"
    t.datetime "updated_at", precision: nil
    t.text "value"
  end

  create_table "short_urls", force: :cascade do |t|
    t.integer "click_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "original_url", null: false
    t.string "short_code", null: false
    t.datetime "updated_at", null: false
    t.index ["short_code"], name: "index_short_urls_on_short_code", unique: true
  end

  create_table "testimonies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "photo_url"
    t.string "profile_url"
    t.boolean "stared"
    t.integer "testimonial_id"
    t.string "testimonial_type"
    t.datetime "updated_at", null: false
    t.index ["testimonial_type", "testimonial_id"], name: "index_testimonies_on_testimonial_type_and_testimonial_id"
  end

  create_table "trainers", force: :cascade do |t|
    t.decimal "average_rating", precision: 4, scale: 2
    t.text "bio"
    t.text "bio_en"
    t.boolean "booking_enabled", default: false
    t.integer "country_id"
    t.datetime "created_at", precision: nil
    t.boolean "deleted", default: false
    t.text "google_access_token"
    t.boolean "google_calendar_connected", default: false
    t.text "google_refresh_token"
    t.datetime "google_token_expires_at"
    t.string "google_uid"
    t.string "gravatar_email"
    t.boolean "is_kleerer"
    t.string "landing"
    t.string "linkedin_url"
    t.text "long_bio"
    t.text "long_bio_en"
    t.string "name"
    t.integer "net_promoter_score"
    t.integer "promoter_count"
    t.string "signature_credentials"
    t.string "signature_image"
    t.integer "surveyed_count"
    t.string "tag_name"
    t.string "twitter_username"
    t.datetime "updated_at", precision: nil
  end

  create_table "translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "resource_id", null: false
    t.integer "trainer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_id", "trainer_id"], name: "index_translations_on_resource_id_and_trainer_id", unique: true
    t.index ["resource_id"], name: "index_translations_on_resource_id"
    t.index ["trainer_id"], name: "index_translations_on_trainer_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "current_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at", precision: nil
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at", precision: nil
    t.datetime "reset_password_sent_at", precision: nil
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0
    t.datetime "updated_at", precision: nil
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.boolean "active"
    t.text "comment"
    t.datetime "created_at", null: false
    t.string "event"
    t.integer "responsible_id"
    t.string "secret"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["responsible_id"], name: "index_webhooks_on_responsible_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "answers", "questions"
  add_foreign_key "articles", "categories"
  add_foreign_key "assessments", "resources"
  add_foreign_key "authorships", "resources"
  add_foreign_key "authorships", "trainers"
  add_foreign_key "bookings", "service_areas"
  add_foreign_key "bookings", "trainers"
  add_foreign_key "contacts", "assessments"
  add_foreign_key "episodes", "podcasts"
  add_foreign_key "event_types", "event_types", column: "canonical_id"
  add_foreign_key "illustrations", "resources"
  add_foreign_key "illustrations", "trainers"
  add_foreign_key "question_groups", "assessments"
  add_foreign_key "questions", "assessments"
  add_foreign_key "questions", "question_groups"
  add_foreign_key "resources", "categories"
  add_foreign_key "responses", "answers"
  add_foreign_key "responses", "contacts"
  add_foreign_key "responses", "questions"
  add_foreign_key "rules", "assessments"
  add_foreign_key "sections", "pages"
  add_foreign_key "services", "service_areas"
  add_foreign_key "translations", "resources"
  add_foreign_key "translations", "trainers"
  add_foreign_key "webhooks", "trainers", column: "responsible_id"
end
