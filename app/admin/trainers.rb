# frozen_string_literal: true

 def signature_list(store)
  list = store.list('signature').map {|obj| File.basename(obj.key)}
  list[0] = ''   # remove first (folder) + add empty option
end

ActiveAdmin.register Trainer do
  menu priority: 4

  permit_params :name, :bio, :bio_en, :gravatar_email, :landing, :twitter_username, :linkedin_url, :tag_name,
  :signature_image, :signature_credentials, :is_kleerer, :deleted, :country_id

  # config.clear_sidebar_sections!
  filter :name


  index title: 'Entrenadores' do
    column :name
    actions
  end

  form do |f|
    signatures = signature_list(FileStoreService.create_s3)

    # f.semantic_errors *f.object.errors.keys
    f.inputs 'Trainer Details' do
      hint_text = 'Supports <a href="https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet" target="_blank">Markdown</a> and HTML.'.html_safe
      f.input :name, label: "Name (*)"
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
      f.input :country_id, as: :select, collection: Country.all.sort_by(&:name).map { |c| [c.name, c.id] }, include_blank: 'Select One...'
      f.input :deleted, as: :boolean
    end
    f.actions do
      f.action :submit, as: :button, label: 'Save', button_html: { class: "btn btn-primary btn-large" }
      f.cancel_link(collection_path, class: "btn btn-large")
    end
  end

end
