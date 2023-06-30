ActiveAdmin.register User do
  config.paginate = false

  actions :index, :show, :edit, :update

  permit_params :id, :email, role_ids: []

  filter :email

  index do
    selectable_column
    id_column
    column :email
    actions
  end

  show do |user|
    panel 'Información de Usuario' do
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
    f.inputs 'Información de Usuario' do
      f.input :email, label: 'Email'
    end
    f.inputs 'Roles' do
      f.input :role_ids, as: :check_boxes, collection: Role.all
    end
    f.actions
  end
end
