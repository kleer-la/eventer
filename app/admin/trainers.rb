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
  scope :deleted

  permit_params :name, :bio, :bio_en, :gravatar_email, :landing, :twitter_username, :linkedin_url, :tag_name,
                :signature_image, :signature_credentials, :is_kleerer, :deleted, :country_id,
                :long_bio, :long_bio_en

  # Remove default action items for destroy
  config.remove_action_item(:destroy)
  action_item :destroy, only: :show do
    if resource.deleted?
      link_to 'Permanently Delete Trainer',
              admin_trainer_path(trainer),
              method: :delete,
              data: { confirm: 'This will permanently remove the trainer. Are you sure?' }
    else
      span '<span>&nbsp;&nbsp; To permanently delete a trainer<br> it should have deleted field set</span>'.html_safe,
           class: 'action_item_disabled'
    end
  end
  member_action :destroy, method: :delete do
    resource.update(deleted: true)
    redirect_to admin_trainers_path, notice: 'Trainer was successfully deleted'
  end
  # config.clear_sidebar_sections!
  filter :name
  filter :bio_present, as: :boolean, label: 'Has Bio'
  filter :bio_en_present, as: :boolean, label: 'Has English Bio'
  filter :long_bio_present, as: :boolean, label: 'Has Long Bio'
  filter :long_bio_en_present, as: :boolean, label: 'Has Long English Bio'

  config.sort_order = 'name_asc'
  index title: 'Entrenadores' do
    column :name do |trainer|
      link_to trainer.name, admin_trainer_path(trainer)
    end
    column :bio do |trainer|
      truncate(trainer.bio || '', length: 40)
    end
    column :bio_en do |trainer|
      truncate(trainer.bio_en || '', length: 40)
    end
    column :deleted

    actions defaults: false do |trainer|
      item 'View', admin_trainer_path(trainer), class: 'member_link'
      item 'Edit', edit_admin_trainer_path(trainer), class: 'member_link'
    end
  end

  form do |f|
    signatures = signature_list(FileStoreService.create_s3)

    # f.semantic_errors *f.object.errors.keys
    f.inputs 'Trainer Details' do
      bio_hint_text = '< 200 characters. Supports <a href="https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet" target="_blank">Markdown</a> and HTML.'.html_safe
      long_bio_hint_text = '< 12 lines. Supports <a href="https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet" target="_blank">Markdown</a> and HTML.'.html_safe
      f.input :name, label: 'Name (*)'
      f.input :bio, as: :text, input_html: { rows: 2 }, hint: bio_hint_text
      f.input :bio_en, as: :text, input_html: { rows: 2 }, hint: bio_hint_text
      f.input :long_bio, as: :text, input_html: { rows: 8 }, hint: long_bio_hint_text
      f.input :long_bio_en, as: :text, input_html: { rows: 8 }, hint: long_bio_hint_text
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
          row :bio_en
          row :long_bio do |trainer|
            markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
            raw markdown.render(trainer.long_bio) if trainer.long_bio.present?
          end
          row :long_bio_en do |trainer|
            markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
            raw markdown.render(trainer.long_bio_en) if trainer.long_bio_en.present?
          end
          row :twitter_username do |trainer|
            if trainer.twitter_username.present?
              link_to "@#{trainer.twitter_username}",
                      "https://twitter.com/#{trainer.twitter_username}"
            end
          end
          row :linkedin_url do |trainer|
            link_to trainer.linkedin_url, trainer.linkedin_url if trainer.linkedin_url.present?
          end
          row :landing do |trainer|
            link_to trainer.landing, trainer.landing if trainer.landing.present?
          end
          row :country
          row :signature_credentials
          row :is_kleerer
          row :deleted
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
