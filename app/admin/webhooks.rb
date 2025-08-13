ActiveAdmin.register Webhook do
  menu label: 'Webhook', parent: 'Others', priority: 100

  permit_params :url, :event, :secret, :active, :responsible_id, :comment

  controller do
    def scoped_collection
      super.includes(:responsible)
    end
  end

  index do
    selectable_column
    id_column
    column :url
    column :event
    column :responsible do |webhook|
      webhook.responsible&.name || webhook.responsible&.email || 'N/A'
    end
    toggle_bool_column 'Active', :active
    column :comment do |webhook|
      truncate(webhook.comment, length: 50) if webhook.comment.present?
    end
    column :secret
    column :created_at
    column :updated_at
    actions
  end

  filter :url
  filter :event
  filter :responsible, as: :select, collection: -> { Trainer.all.pluck(:name, :id) }
  filter :active, as: :select, collection: [['Yes', true], ['No', false]], label: 'Active'
  filter :created_at

  form do |f|
    f.inputs do
      f.input :url
      f.input :event
      f.input :responsible, as: :select, collection: Trainer.all.pluck(:name, :id), 
              include_blank: false, label: 'Responsible Trainer'
      f.input :comment, as: :text, input_html: { rows: 4 }
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
      row :responsible do |webhook|
        if webhook.responsible
          link_to webhook.responsible.name, admin_trainer_path(webhook.responsible)
        else
          'N/A'
        end
      end
      row :comment
      row :active do |webhook|
        webhook.active? ? 'Yes' : 'No'
      end
      row :secret
      row :created_at
      row :updated_at
    end
  end
end
