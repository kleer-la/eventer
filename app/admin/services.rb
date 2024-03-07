ActiveAdmin.register Service do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :name, :card_description, :subtitle, :service_area_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :card_description, :subtitle, :service_area_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  index do
    selectable_column
    id_column
    column :name
    column :subtitle
    column :card_description
    column :service_area if defined?(ServiceArea) # Optional: Display associated ServiceArea if relevant
    actions
  end

  filter :name
  filter :subtitle
  filter :service_area if defined?(ServiceArea) # Optional: Filter by ServiceArea if relevant

  form do |f|
    f.inputs do
      f.input :name
      f.input :subtitle
      f.input :card_description, as: :text
      f.input :service_area if defined?(ServiceArea) # Optional: Select ServiceArea if relevant
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :subtitle
      row :card_description
      row :service_area if service.service_area # Optional: Show ServiceArea if relevant
      # other attributes...
    end
  end
end
