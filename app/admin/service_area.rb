# frozen_string_literal: true

ActiveAdmin.register ServiceArea do
  permit_params :name, :slug, :icon, :primary_color, :secondary_color, :visible, :summary,
                :side_image, :slogan, :subtitle, :description, :target, :value_proposition
  filter :name

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  action_item :new_service, only: :edit do
    link_to 'New Service', new_admin_service_path(service_area_id: resource.id)
  end

  form do |f|
    f.semantic_errors # Shows errors on :base
    f.inputs 'ServiceArea Details' do
      f.input :name
      f.input :slug, hint: 'The URL-friendly version of the name. (Empty to auto generete)'
      f.input :visible, as: :boolean
      f.input :icon, as: :url
      f.input :primary_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :secondary_color, as: :color, input_html: { style: 'width: 100%;' } 
      f.input :summary, as: :rich_text_area
      f.input :side_image, as: :url
      f.input :slogan, as: :rich_text_area
      f.input :subtitle, as: :rich_text_area
      f.input :description, as: :rich_text_area
      f.input :target, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
    end

    panel "Existing Services" do
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
    attributes_table do
      row :name
      row :slug
      row :visible
      row :icon do |service_area|
        if service_area.icon.present?
          image_tag service_area.icon, width: '50px', alt: 'Service Area Icon'
        else
          text_node 'No Icon defined'
        end
      end

      row :primary_color do |service_area|
        div style: "width: 30px; height: 30px; background-color: #{service_area.primary_color};" if service_area.primary_color.present?
        text_node service_area.primary_color
      end

      row :secondary_color do |service_area|
        div style: "width: 30px; height: 30px; background-color: #{service_area.secondary_color};" if service_area.secondary_color.present?
        text_node service_area.secondary_color
      end
      # This will safely render the rich text content, including formatting and attachments.
      row :summary do |service_area| 
        service_area.summary.to_s.html_safe if service_area.summary.present?
      end
      row :side_image
      row :slogan do |service_area| 
        service_area.slogan.to_s.html_safe if service_area.slogan.present?
      end
      row :subtitle do |service_area| 
        service_area.subtitle.to_s.html_safe if service_area.subtitle.present?
      end
      row :description do |service_area| 
        service_area.description.to_s.html_safe if service_area.description.present?
      end
      row :target do |service_area| 
        service_area.target.to_s.html_safe if service_area.target.present?
      end
      row :value_proposition do |service_area| 
        service_area.value_proposition.to_s.html_safe if service_area.value_proposition.present?
      end
      if service_area.side_image.present?
        div 'Side Image '
        div do
          image_tag service_area.side_image
        end
      end
    end
    panel 'Services' do 
      table_for service_area.services do
        column :name do |service|
          link_to service.name, admin_service_path(service)
        end
        column :subtitle
      end
    end
  end
end
