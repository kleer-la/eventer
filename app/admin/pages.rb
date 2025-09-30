# frozen_string_literal: true

ActiveAdmin.register Page do
  menu parent: 'Assets', priority: 11

  permit_params :name, :slug, :seo_title, :seo_description, :lang, :canonical, :cover,
                recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy],
                sections_attributes: %i[id title content position slug cta_text cta_url _destroy]

  filter :name
  filter :lang, as: :select, collection: Page.langs

  controller do
    def scoped_collection
      super.includes(:sections)
    end

    def find_resource
      scoped_collection.find_by_param!(params[:id])
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

  show do
    attributes_table do
      row :id
      row :name
      row :slug
      row :lang
      row :seo_title
      row :seo_description
      row :canonical
      row :cover do |page|
        if page.cover.present?
          div do
            image_tag page.cover, style: 'max-width: 300px; max-height: 300px'
          rescue Sprockets::Rails::Helper::AssetNotFound
            content_tag :p, 'Image not available', class: 'asset-missing'
          end
          div do
            link_to page.cover, page.cover, target: '_blank'
          end
        end
      end
      row :created_at
      row :updated_at
    end
    panel 'Recommended Content' do
      table_for resource.recommended do
        column :relevance_order do |recommendation|
          recommendation['relevance_order']
        end
        column :title do |recommendation|
          recommendation['title']
        end
        column :type do |recommendation|
          recommendation['type']
        end
        column :subtitle do |recommendation|
          recommendation['subtitle']
        end
      end
    end
    panel 'Sections' do
      table_for resource.sections.order(:position) do
        column :title
        column :slug
        column :content do |section|
          truncate(section.content, length: 100) # Shorten long content
        end
        column :cta_text
        column :cta_url
        column :position
      end
    end
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
      f.input :cover, as: :url
    end

    f.inputs 'Recommended Contents' do
      f.has_many :recommended_contents, allow_destroy: true, new_record: true do |rc|
        rc.input :target_type, as: :select,
                               collection: %w[Article EventType Service Resource],
                               input_html: { class: 'target-type-select' }
        rc.input :target_id, label: 'Target', as: :select,
                             collection: [],
                             input_html: { class: 'target-id-select' }
        rc.input :relevance_order
        rc.input :current_target_info, as: :hidden,
                                       input_html: {
                                         class: 'current-target-info',
                                         value: { type: rc.object.target_type, id: rc.object.target_id }.to_json
                                       }
      end
      f.inputs 'Sections' do
        f.has_many :sections, allow_destroy: true, new_record: true, heading: 'Page Sections' do |s|
          s.input :title
          s.input :slug, hint: 'Generated from title if left blank'
          s.input :content, as: :text, input_html: { rows: 5 }
          s.input :cta_text
          s.input :cta_url
          s.input :position, hint: 'Order of appearance (lower numbers first)'
        end
      end
    end

    f.actions
    script do
      raw RecommendableHelper.recommended_content_js(Page)
    end
  end
end
