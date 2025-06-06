ActiveAdmin.register ShortUrl do
  permit_params :original_url, :short_code

  index do
    selectable_column
    id_column
    column :short_code
    column :original_url
    column :click_count
    column :created_at
    column :updated_at
    actions
  end

  filter :short_code
  filter :original_url
  filter :click_count
  filter :created_at
  filter :updated_at

  form do |f|
    f.semantic_errors # Display validation errors
    f.inputs do
      f.input :original_url, hint: 'Must be a valid HTTP/HTTPS URL (e.g., https://example.com)'
      f.input :short_code, hint: '4-16 characters (letters, numbers, hyphens, underscores). Leave blank to auto-generate a 6-character code.'
    end
    f.actions
  end

  show do
    attributes_table do
      row :short_code
      row :original_url
      row :click_count
      row :created_at
      row :updated_at
      row :short_url do |short_url|
        short_url_path = "#{Rails.configuration.short_url_base}/s/#{short_url.short_code}"
        link_to short_url_path, short_url_path, target: '_blank'
      end
    end
  end

  # Controller customizations
  controller do
    def create
      # Ensure short_code is nil if blank to trigger auto-generation
      params[:short_url][:short_code] = nil if params[:short_url][:short_code].blank?
      super
    end

    def update
      # Ensure short_code is nil if blank to trigger auto-generation
      params[:short_url][:short_code] = nil if params[:short_url][:short_code].blank?
      super
    end
  end
end