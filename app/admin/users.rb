# frozen_string_literal: true

ActiveAdmin.register User do
  menu label: 'Usuarios', parent: 'Others', priority: 90

  actions :index, :show, :edit, :update, :new, :create, :destroy

  permit_params :email, :password, :password_confirmation, role_ids: []

  controller do
    def scoped_collection
      super.includes(:roles)
    end
  end

  filter :email

  index do
    selectable_column
    id_column
    column 'Email', :email
    column 'Roles' do |o|
      o.roles.map(&:name).join(', ')
    end
    actions defaults: true do |user|
      item 'Cambiar clave', "#{edit_admin_user_path(user)}?change_password=1", method: :get
    end
  end

  batch_action :add_role, form: -> { { role_id: Role.pluck(:name, :id) } } do |ids, inputs|
    role = Role.find(inputs['role_id'])
    users = User.where(id: ids)

    users.each do |user|
      user.roles << role unless user.roles.include?(role)
    end

    redirect_to collection_path, notice: "Role '#{role.name}' added to #{users.count} user(s)"
  end

  batch_action :remove_role, form: -> { { role_id: Role.pluck(:name, :id) } } do |ids, inputs|
    role = Role.find(inputs['role_id'])
    users = User.where(id: ids)

    users.each do |user|
      user.roles.delete(role) if user.roles.include?(role)
    end

    redirect_to collection_path, notice: "Role '#{role.name}' removed from #{users.count} user(s)"
  end

  sidebar 'Role Permissions Summary', only: :index do
    table_for [
      { role: 'comercial', permissions: 'Read only' },
      { role: 'content', permissions: 'Read + Create/Update Content*' },
      { role: 'publisher', permissions: 'Content + Set Publishing Fields' },
      { role: 'marketing', permissions: 'Read + Create/Update All' },
      { role: 'administrator', permissions: 'Full access (including Delete)' }
    ] do
      column('Role') { |r| r[:role] }
      column('Permissions') { |r| r[:permissions] }
    end
    para do
      text_node '*Content: Event, EventType, Participant, Coupon, Article, Resource, Podcast, Episode, Assessment, News, Testimony'
    end
    para do
      text_node 'Publishing fields: include_in_catalog, published'
    end
  end

  show do |user|
    panel 'Información de usuario' do
      attributes_table_for user do
        row('Email', &:email)
        row('Roles') { |user| user.roles.map(&:name).join(', ') }
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
