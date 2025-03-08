# app/admin/contacts.rb
ActiveAdmin.register Contact do
  menu parent: 'Mail'

  # Read-only as contacts are created from frontend
  actions :index, :show, :destroy
  config.clear_action_items!

  # Filters
  filter :email
  filter :trigger_type
  filter :status
  filter :created_at
  filter :processed_at
  filter :resource_slug
  filter :can_we_contact, as: :select
  filter :suscribe, as: :select

  # Scopes for quick filtering
  scope :last_24h
  scope :all
  scope :pending
  scope :processed
  scope :failed

  action_item :toggle_view, only: :index do
    if params[:grouped] == 'true'
      link_to 'Show Regular View', admin_contacts_path(grouped: nil)
    else
      link_to 'Show Grouped View', admin_contacts_path(grouped: true)
    end
  end

  action_item :destroy, only: :show do
    link_to 'Delete Contact', admin_contact_path(contact),
            method: :delete,
            data: { confirm: 'Are you sure you want to delete this contact?' }
  end

  # Index view
  index do
    if params[:grouped]
      selectable_column
      id_column
      column :created_at
      column :trigger_type
      column :email
      column 'Name' do |contact|
        contact.form_data&.dig('name')
      end
      column 'Company' do |contact|
        contact.form_data&.dig('company')
      end
      column 'Resource' do |contact|
        resources = Contact.where(email: contact.email)
                           .where('DATE(created_at) = ?', contact.created_at.to_date)
                           .map do |c|
          c.form_data&.dig('resource_slug')
        end.compact
        resources.join(', ')
      end
      actions defaults: false do |contact|
        item 'View', admin_contact_path(contact)
      end
    else
      selectable_column
      id_column
      column :email
      column :trigger_type
      column :status
      column 'Name' do |contact|
        contact.form_data&.dig('name')
      end
      column 'Company' do |contact|
        contact.form_data&.dig('company')
      end
      column 'Slug' do |contact|
        contact.form_data&.dig('resource_slug')
      end
      column :created_at
      column :resource_slug         # Changed from form_data dig
      column :can_we_contact        # New column
      column :suscribe
      actions defaults: false do |contact|
        item 'View', admin_contact_path(contact)
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :email
      row :trigger_type
      row :status
      row :resource_slug
      row :can_we_contact
      row :suscribe
      row :created_at
      row :processed_at
      row :form_data do |contact|
        content_tag :pre, JSON.pretty_generate(contact.form_data)
      end
      if contact.assessment.present?
        panel 'Responses' do
          table_for contact.responses do
            column :id
            column :question
            column :answer
            column 'Position' do |response|
              response.answer.position
            end
          end
        end
      end
      row :assessment_report_url
      if contact.assessment_report_url.present?
        row 'Assessement report' do
          if contact.assessment_report_url.end_with?('.pdf')
            embed src: contact.assessment_report_url,
                  type: 'application/pdf',
                  width: '100%',
                  height: '600px'
          else
            image_tag contact.assessment_report_url, style: 'max-width: 500px; max-height: 500px;'
          end
        end
      end
    end
  end

  # CSV Export
  csv do
    column :id
    column :email
    column :trigger_type
    column :status
    column :resource_slug
    column :can_we_contact
    column :suscribe
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

  controller do
    def scoped_collection
      if params[:grouped]
        date_sql = if ActiveRecord::Base.connection.adapter_name.downcase == 'sqlite'
                     "strftime('%Y-%m-%d', created_at)"
                   else
                     'DATE(created_at)'
                   end
        grouped_ids = Contact.group(date_sql, :trigger_type, :email)
                             .pluck('MIN(id) as id')
        Contact.where(id: grouped_ids).reorder(created_at: :desc)
      else
        super
      end
    end
  end
end
