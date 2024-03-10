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
    column :service_area if defined?(ServiceArea) # Optional: Display associated ServiceArea if relevant
    actions
  end

  filter :name
  filter :subtitle
  filter :service_area if defined?(ServiceArea) # Optional: Filter by ServiceArea if relevant

  form do |f|
    selected_service_area_id = params[:service_area_id] || f.object.service_area_id

    f.inputs do
      f.input :service_area, as: :select, collection: ServiceArea.all.map{ |sa| [sa.name, sa.id] }, selected: selected_service_area_id
      f.input :name
      f.input :subtitle, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
      f.input :outcomes, as: :rich_text_area
      f.input :program, as: :rich_text_area
      f.input :target, as: :rich_text_area
      f.input :faq, as: :rich_text_area
    end
    f.actions
  end

  show do
    attributes_table do
      row :service_area if service.service_area # Optional: Show ServiceArea if relevant
      row :name
      row :subtitle
      row :value_proposition do |service| 
        service.value_proposition.to_s.html_safe if service.value_proposition.present?
      end
    end
  end
end
