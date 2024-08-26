# frozen_string_literal: true

ActiveAdmin.register Page do
  menu priority: 2 # Adjust as needed

  permit_params :name, :slug, :seo_title, :seo_description, :lang, :canonical, :content

  filter :name
  filter :lang, as: :select, collection: Page.langs

  controller do
    def find_resource
      lang, *slug_parts = params[:id].split('-')
      slug = slug_parts.join('-')

      if slug.present?
        scoped_collection.where(lang:).friendly.find(slug)
      else
        scoped_collection.find_by!(lang:, slug: nil)
      end
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :lang
    column :created_at
    column :updated_at
    actions
    # defaults: false do |page|
    #   item 'View', admin_page_path(page.to_param), class: 'member_link'
    #   item 'Edit', edit_admin_page_path(page.to_param), class: 'member_link'
    #   item 'Delete', admin_page_path(page.to_param), method: :delete,
    #                                                  data: { confirm: 'Are you sure you want to delete this?' }, class: 'member_link'
    # end
  end

  form do |f|
    f.semantic_errors # Shows errors on :base
    f.inputs 'Page Details' do
      f.input :name
      f.input :lang, as: :radio
      # f.input :slug, hint: 'Leave empty to auto-generate from name. Use nil for homepage.'
      f.input :slug, input_html: { disabled: f.object.home_page? },
                     hint: f.object.home_page? ? 'Home pages cannot have a custom slug' : 'Leave empty to auto-generate from name'

      f.input :seo_title
      f.input :seo_description
      f.input :canonical, hint: 'Leave empty to auto-generate'
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :lang
      row :seo_title
      row :seo_description
      row :canonical
      row :created_at
      row :updated_at
    end
  end

  # sidebar 'Page Details', only: %i[show edit] do
  #   ul do
  #     li link_to 'View on site', "/#{page.lang}/#{page.slug || ''}"
  #   end
  # end
end
