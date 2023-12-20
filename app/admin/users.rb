ActiveAdmin.register User do
  menu label: 'Usuarios', parent: 'Others', priority: 90

  actions :index, :show, :edit, :update, :new, :create, :destroy

  permit_params :email, :password, :password_confirmation, role_ids: []

  filter :email

  index do
    selectable_column
    id_column
    column 'Email', :email
    column 'Roles' do |o|
      o.roles.map { |r| r.name }.join(', ')
    end
    actions defaults: true do |user|
      item 'Cambiar clave', edit_admin_user_path(user) + '?change_password=1', method: :get
    end
  end

  show do |user|
    panel 'Información de usuario' do
      attributes_table_for user do
        row('Email') { |user| user.email }
        row('Roles') { |user| user.roles.map { |role| role.name }.join(', ') }
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs 'Información de usuario' do
      if f.object.new_record?
        f.input :email, label: 'Email'
        f.input :role_ids, label: 'Roles', as: :tags, collection: Role.all
        f.input :password, label: 'Clave'
        f.input :password_confirmation, label: 'Confirme clave'
      elsif params['change_password'].present?
        f.input :password, label: 'Clave'
        f.input :password_confirmation, label: 'Confirme clave'
      else
        f.input :email, label: 'Email'
        f.input :role_ids, label: 'Roles', as: :tags, collection: Role.all
      end
    end
    f.actions
  end
end
