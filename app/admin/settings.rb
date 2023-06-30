ActiveAdmin.register Setting do
  menu label: 'Settings', priority: 1004

  actions :index, :show, :edit, :update, :new, :create, :destroy

  permit_params :key, :value

  filter :key
  filter :value

  index do
    selectable_column
    id_column
    column 'Clave', :key
    column 'Valor', :value
    actions
  end

  show do |setting|
    panel 'Información de la configuración' do
      attributes_table_for setting do
        row('Clave') { |o| o.key }
        row('Valor') { |o| o.value }
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Información de la configuración' do
      f.input :key, label: 'Clave'
      f.input :value, label: 'Valor'
    end
    f.actions
  end
end
