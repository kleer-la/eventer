ActiveAdmin.register Role do
  menu label: 'Roles', priority: 1002

  actions :index, :show, :edit, :update, :new, :create

  permit_params :name

  filter :name

  index do
    selectable_column
    id_column
    column 'Nombre', :name
    actions
  end

  show do |role|
    panel 'Información del rol' do
      attributes_table_for role do
        row('Nombre') { |o| o.name }
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Información del rol' do
      f.input :name, label: 'Nombre'
    end
    f.actions
  end
end
