ActiveAdmin.register User do
  menu label: 'Usuarios', priority: 1001

  actions :index, :show, :edit, :update, :new, :create, :destroy

  permit_params :email, :password, :password_confirmation, role_ids: []

  filter :email

  index do
    selectable_column
    id_column
    column 'Email', :email
    actions
  end

  show do |user|
    panel 'Información de usuario' do
      attributes_table_for user do
        row('Email') { |o| o.email }
      end
    end

    panel 'Roles' do
      table_for user.roles do
        column :name
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Información de usuario' do
      f.input :email, label: 'Email'
      f.input :password, label: 'Clave'
      f.input :password_confirmation, label: 'Confirme clave'
    end
    f.inputs 'Roles' do
      f.input :role_ids, as: :check_boxes, collection: Role.all
    end
    f.actions
  end
end
