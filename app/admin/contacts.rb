# app/admin/contacts.rb
ActiveAdmin.register Contact do
  menu parent: 'Mail'

  # Read-only as contacts are created from frontend
  actions :all, except: %i[new create edit update]

  # Filters
  filter :email
  filter :trigger_type
  filter :status
  filter :created_at
  filter :processed_at

  # Scopes for quick filtering
  scope :last_24h
  scope :all
  scope :pending
  scope :processed
  scope :failed

  # Index view
  index do
    selectable_column
    id_column
    column :email
    column :trigger_type
    column :status
    column :created_at
    column :processed_at
    column :form_data do |contact|
      truncate(contact.form_data.to_s, length: 50)
    end
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :trigger_type
      row :status
      row :created_at
      row :processed_at
      row :form_data do |contact|
        content_tag :pre, JSON.pretty_generate(contact.form_data)
      end
    end
  end

  # CSV Export
  csv do
    column :id
    column :email
    column :trigger_type
    column :status
    column :created_at
    column :processed_at
    column(:form_data) { |contact| contact.form_data.to_json }
  end

  # Sidebar stats
  sidebar 'Stats', only: :index do
    div class: 'panel_contents' do
      table do
        tr do
          th 'Total Contacts'
          td Contact.count
        end
        tr do
          th 'Last 24h'
          td Contact.last_24h.count
        end
        tr do
          th 'Pending'
          td Contact.pending.count
        end
        tr do
          th 'By Type'
          td do
            Contact.group(:trigger_type).count.map do |type, count|
              "#{type}: #{count}"
            end.join(', ')
          end
        end
      end
    end
  end

  # Custom action to resend notification
  action_item :resend, only: :show do
    link_to 'Resend Notification', resend_admin_contact_path(contact), method: :post if contact.processed?
  end

  member_action :resend, method: :post do
    contact = Contact.find(params[:id])
    # Add your resend logic here
    redirect_to admin_contact_path(contact), notice: 'Notification queued for resending'
  end
end
