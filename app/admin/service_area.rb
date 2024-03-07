# frozen_string_literal: true

ActiveAdmin.register ServiceArea do
  permit_params :name, :abstract, :icon, :primary_color, :secondary_color

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
      f.input :abstract, as: :rich_text_area
      f.input :icon, as: :url
      f.input :primary_color, as: :color, input_html: { style: 'width: 100%;' }
      f.input :secondary_color, as: :color, input_html: { style: 'width: 100%;' } 
    end

    panel "Existing Services" do
      ul do
        resource.services.each do |service|
          li do
            span link_to service.name, edit_admin_service_path(service)
            span  service.subtitle
          end
        end
      end
    end
  
    f.actions         # Adds the 'Submit' and 'Cancel' buttons
  end

  show do
    attributes_table do
      row :name
  
      row :abstract do |service_area|
        # This will safely render the rich text content, including formatting and attachments.
        service_area.abstract.to_s.html_safe if service_area.abstract.present?
      end
  
      row :icon do |service_area|
        # Assuming 'icon' stores a URL, you can use 'link_to' to make it clickable.
        link_to service_area.icon, service_area.icon, target: '_blank', rel: 'noopener' if service_area.icon.present?
      end
  
      row :primary_color do |service_area|
        # Display the color with a visual indicator.
        div style: "width: 30px; height: 30px; background-color: #{service_area.primary_color};" if service_area.primary_color.present?
        text_node service_area.primary_color
      end
  
      row :secondary_color do |service_area|
        # Display the color with a visual indicator.
        div style: "width: 30px; height: 30px; background-color: #{service_area.secondary_color};" if service_area.secondary_color.present?
        text_node service_area.secondary_color
      end
    end
    panel "Services" do 
      table_for service_area.services do
        column :name do |service|
          link_to service.name, admin_service_path(service)
        end
        column :subtitle
        column :card_description
        # Add other service attributes here
      end
    end
  end
end
