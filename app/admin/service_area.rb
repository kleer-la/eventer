# frozen_string_literal: true

ActiveAdmin.register ServiceArea do
  menu parent: 'Services Mgnt'

  permit_params :name, :slug, :icon, :primary_color, :secondary_color, :primary_font_color, :secondary_font_color,
                :visible, :summary, :cta_message,
                :side_image, :slogan, :subtitle, :description, :target, :value_proposition, :ordering,
                :target_title, :seo_title, :seo_description, :is_training_program
  filter :name

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id].strip)
    end
  end

  action_item :new_service, only: :edit do
    link_to 'New Service', new_admin_service_path(service_area_id: resource.id)
  end

  index do
    selectable_column
    id_column
    column :name
    column :subtitle
    column :slug
    column :ordering
    column :is_training_program
    column :visible
    actions
  end

  form do |f|
    f.semantic_errors # Shows errors on :base
    f.inputs 'ServiceArea Details' do
      f.input :name
      f.input :slug, hint: 'The URL-friendly version of the name. (Empty to auto generete)'
      f.input :visible, as: :boolean
      f.input :is_training_program, as: :boolean
      f.input :icon, as: :url
      f.input :primary_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :primary_font_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :secondary_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :secondary_font_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :summary, as: :rich_text_area
      f.input :cta_message, as: :rich_text_area,
                            hint: 'This text is shown just before the buttons. Example: <span style="font-style: normal;">Learn more of the <b>Your Service Name</b></span>'.html_safe
      f.input :side_image, as: :url
      f.input :slogan, as: :rich_text_area
      f.input :subtitle, as: :rich_text_area
      f.input :description, as: :rich_text_area
      f.input :target_title
      f.input :target, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
      f.input :ordering
      f.input :seo_title
      f.input :seo_description
    end

    panel 'Existing Services' do
      ul do
        resource.services.each do |service|
          li do
            span link_to service.name, edit_admin_service_path(service)
            span service.subtitle
          end
        end
      end
    end

    f.actions         # Adds the 'Submit' and 'Cancel' buttons
  end

  show do
    def rich_row(field)
      row field do |service_area|
        service_area.send(field).to_s.html_safe if service_area.send(field).present?
      end
    end

    attributes_table do
      row :name
      row :slug
      row :visible
      row :is_training_program
      row :icon do |service_area|
        if service_area.icon.present?
          image_tag service_area.icon, width: '50px', alt: 'Service Area Icon'
        else
          text_node 'No Icon defined'
        end
      end

      %i[primary_color primary_font_color secondary_color secondary_font_color].each do |color_field|
        row color_field do |service_area|
          color_value = service_area.send(color_field)
          div style: "width: 30px; height: 30px; background-color: #{color_value};" if color_value.present?
          text_node color_value
        end
      end

      %i[primary secondary].each do |type|
        row type do |record|
          bg_color = record.send("#{type}_color")
          font_color = record.send("#{type}_font_color")

          next unless bg_color.present? && font_color.present?

          div style: 'margin: 10px 0;' do
            div style: 'display: inline-block; padding: 8px 16px; border-radius: 4px; ' \
                      "background-color: #{bg_color}; " \
                      "color: #{font_color};" do
              "#{type.to_s.titleize} Button Preview"
            end
          end
        end
      end

      # This will safely render the rich text content, including formatting and attachments.
      rich_row :summary
      rich_row :cta_message
      row :side_image
      rich_row :slogan
      rich_row :subtitle
      rich_row :description
      row :target_title
      rich_row :target
      rich_row :value_proposition
      row :ordering
      row :seo_title
      row :seo_description
      if service_area.side_image.present?
        div 'Side Image '
        div do
          image_tag service_area.side_image
        end
      end
    end
    panel 'Services' do
      table_for service_area.services.order(:ordering) do
        column :name do |service|
          link_to service.name, admin_service_path(service)
        end
        column :subtitle
        column :ordering
      end
    end
    panel 'Testimonies' do
      table_for service_area.testimonies do
        column :first_name
        column :last_name
        column :profile_url do |testimony|
          link_to testimony.profile_url, testimony.profile_url, target: '_blank' if testimony.profile_url.present?
        end
        column :photo_url do |testimony|
          image_tag testimony.photo_url if testimony.photo_url.present?
        end
        column :testimony do |testimony|
          div testimony.testimony.body.to_s.html_safe
        end
        column :stared
        column '' do |testimony|
          link_to 'Edit', edit_admin_testimony_path(testimony), class: 'edit_link'
        end
      end
    end
  end
end
