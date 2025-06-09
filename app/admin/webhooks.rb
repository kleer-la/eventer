ActiveAdmin.register Webhook do
  menu label: 'Webhook', parent: 'Others', priority: 100

  permit_params :url, :event, :secret, :active

  index do
    selectable_column
    id_column
    column :url
    column :event
    column :active do |webhook|
      webhook.active? ? 'Yes' : 'No'
    end
    column :secret
    column :created_at
    column :updated_at
    actions
  end

  filter :url
  filter :event
  filter :active, as: :select, collection: [['Yes', true], ['No', false]], label: 'Active'
  filter :created_at

  form do |f|
    f.inputs do
      f.input :url
      f.input :event
      f.input :active, as: :boolean, label: 'Active', input_html: { checked: true } # Default to active
      # Secret is generated automatically, but can be shown if needed
      f.input :secret
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :url
      row :event
      row :active do |webhook|
        webhook.active? ? 'Yes' : 'No'
      end
      row :secret
      row :created_at
      row :updated_at
    end
  end
end
