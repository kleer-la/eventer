# frozen_string_literal: true

def signature_list(store)
  list = store.list('signature').map { |obj| File.basename(obj.key) }
  list[0] = '' # remove first (folder) + add empty option
  list
end

ActiveAdmin.register Trainer do
  menu parent: 'Others'

  actions :index, :show, :edit, :update, :new, :create # , :destroy

  scope :all, default: false
  scope :active, default: true

  permit_params :name, :bio, :bio_en, :gravatar_email, :landing, :twitter_username, :linkedin_url, :tag_name,
                :signature_image, :signature_credentials, :is_kleerer, :deleted, :country_id

  # config.clear_sidebar_sections!
  filter :name
  filter :deleted

  config.sort_order = 'name_asc'
  index title: 'Entrenadores' do
    column :name do |trainer|
      link_to trainer.name, admin_trainer_path(trainer)
    end
    column :deleted

    actions
    # actions defaults: false do |trainer|
    #   link_to 'Edit', edit_admin_trainer_path(trainer)
    # end
  end

  form do |f|
    signatures = signature_list(FileStoreService.create_s3)

    # f.semantic_errors *f.object.errors.keys
    f.inputs 'Trainer Details' do
      hint_text = 'Supports <a href="https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet" target="_blank">Markdown</a> and HTML.'.html_safe
      f.input :name, label: 'Name (*)'
      f.input :bio, as: :text, input_html: { rows: 8 }, hint: hint_text
      f.input :bio_en, as: :text, input_html: { rows: 8 }, hint: hint_text
      f.input :gravatar_email
      f.input :landing
      f.input :twitter_username
      f.input :linkedin_url
      f.input :tag_name
      f.input :signature_image, as: :select, collection: signatures
      f.input :signature_credentials
      f.input :is_kleerer, as: :boolean
      f.input :country_id, as: :select, collection: Country.all.sort_by(&:name).map { |c|
                                                      [c.name, c.id]
                                                    }, include_blank: 'Select One...'
      f.input :deleted, as: :boolean
    end
    f.actions do
      f.action :submit, as: :button, label: 'Save', button_html: { class: 'btn btn-primary btn-large' }
      f.cancel_link(collection_path, class: 'btn btn-large')
    end
  end

  show do
    columns do
      column do # left column
        attributes_table do
          row :image do |trainer|
            image_tag trainer.gravatar_picture_url if trainer.gravatar_email.present?
          end
          row :name
          row :bio
          row :twitter_username
          row :linkedin_url
          row :landing
          # :bio_en, :gravatar_email, :signature_image, :signature_credentials, :is_kleerer, :deleted, :country_id
        end
      end

      column do
        if trainer.event_types.included_in_catalog.count.positive?
          panel 'Event Types' do
            ul do
              trainer.event_types.included_in_catalog.order(:name).each do |et|
                li link_to(et.name, edit_event_type_path(et))
              end
            end
          end
        end
        if trainer.articles.count.positive?
          panel 'Articles' do
            ul do
              trainer.articles.order(:title).each do |el|
                li link_to(el.title, edit_article_path(el))
              end
            end
          end
        end
        if trainer.authorships.count.positive?
          panel 'Resources' do
            # h3 'Author'
            ul do
              trainer.authorships.each do |el|
                li link_to(el.resource.title_es, edit_resource_path(el))
              end
            end
            # h3 'Translator'
            ul do
              trainer.translators.each do |el|
                li link_to(el.resource.title_es, edit_resource_path(el))
              end
            end
          end
        end
        if trainer.news.count.positive?
          panel 'News' do
            ul do
              trainer.news.each do |el|
                li link_to(el.title, edit_news_path(el))
              end
            end
          end
        end
      end
    end
  end
end
