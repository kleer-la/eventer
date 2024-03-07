# frozen_string_literal: true

ActiveAdmin.register ServiceArea do
  permit_params :name, description: []

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
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
    f.actions         # Adds the 'Submit' and 'Cancel' buttons
  end

  show do
    attributes_table do
      row :name
      row :abstract do |service_area|
        # This will render the rich text content with formatting and attachments
        service_area.abstract
      end
    end
  end
end
