# app/admin/contacts.rb
ActiveAdmin.register Contact do
  menu parent: 'Mail'

  # Read-only as contacts are created from frontend
  actions :index, :show, :destroy
  config.clear_action_items!

  # Filters
  filter :email
  filter :trigger_type, as: :select, collection: Contact.trigger_types.keys
  filter :status, as: :select, collection: Contact.statuses.keys
  filter :created_at
  filter :resource_slug
  filter :content_updates_opt_in, as: :select
  filter :newsletter_opt_in, as: :select
  filter :newsletter_added, as: :select

  # Scopes for quick filtering
  scope :last_24h
  scope :all
  scope :pending
  scope :completed
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

  action_item :update_status, only: :show do
    # Mostrar un enlace para cada estado posible, excepto el estado actual
    Contact.statuses.keys.map do |status|
      next if status == contact.status # No mostrar el estado actual

      link_to "Mark as #{status.humanize}", update_status_admin_contact_path(contact, status:),
              method: :post,
              class: 'button',
              data: { confirm: "Are you sure you want to mark this contact as #{status.humanize}?" }
    end.join(' ').html_safe
  end
  action_item :toggle_newsletter_added, only: :show do
    new_value = !contact.newsletter_added
    label = new_value ? 'Add to Newsletter' : 'Remove from Newsletter'
    link_to label, toggle_newsletter_added_admin_contact_path(contact, newsletter_added: new_value),
            method: :post,
            class: 'button',
            data: { confirm: "Are you sure you want to #{new_value ? 'add this contact to' : 'remove this contact from'} the newsletter?" }
  end

  batch_action :mark_as_completed do |ids|
    Contact.where(id: ids).update_all(status: :completed, processed_at: Time.current)
    redirect_to collection_path, notice: "#{ids.count} contacts marked as completed."
  end
  batch_action :add_to_newsletter, confirm: 'Are you sure you want to add these contacts to the newsletter?' do |ids|
    Contact.where(id: ids).update_all(newsletter_added: true)
    redirect_to collection_path, notice: "#{ids.count} contacts added to the newsletter."
  end

  member_action :update_status, method: :post do
    new_status = params[:status]
    if Contact.statuses.key?(new_status)
      resource.update(status: new_status)
      redirect_to admin_contact_path(resource), notice: "Status updated to #{new_status}"
    else
      redirect_to admin_contact_path(resource), alert: 'Invalid status'
    end
  end
  member_action :toggle_newsletter_added, method: :post do
    new_value = params[:newsletter_added] == 'true'
    resource.update(newsletter_added: new_value)
    redirect_to admin_contact_path(resource),
                notice: "Contact #{new_value ? 'added to' : 'removed from'} the newsletter."
  end

  # Index view
  index do
    if params[:grouped]
      selectable_column
      id_column
      column :created_at
      column :trigger_type
      column :email
      column :name
      column :company
      column 'Resources' do |contact|
        Contact.where(email: contact.email)
               .where('DATE(created_at) = ?', contact.created_at.to_date)
               .pluck(:resource_slug)
               .compact
               .join(', ')
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
      column :name
      column :company
      column :resource_slug
      column :created_at
      column :resource_slug # Changed from form_data dig
      column :content_updates_opt_in # New column
      column :newsletter_opt_in
      column :newsletter_added

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
      row :name
      row :company
      row :resource_slug
      row :content_updates_opt_in
      row :newsletter_opt_in
      row :newsletter_added
      row :created_at
      row :processed_at
      row :form_data do |contact|
        content_tag :pre, JSON.pretty_generate(contact.form_data)
      end
      if contact.assessment.present?
        panel 'Responses' do
          table_for contact.responses do
            column :id
            column :question do |response|
              "#{response.question.name} (#{response.question.question_type})"
            end
            column 'Response' do |response|
              if response.answer.present?
                "#{response.answer.text} (pos: #{response.answer.position})"
              elsif response.text_response.present?
                response.text_response
              else
                'No response'
              end
            end
          end
        end
      end
      row :assessment_report_url
      if contact.assessment_report_url.present?
        row 'Assessement report' do
          image_tag contact.assessment_report_url.sub('.pdf', '.png'), style: 'max-width: 500px; max-height: 500px;'
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
    column :name
    column :company
    column :resource_slug
    column :content_updates_opt_in
    column :newsletter_opt_in
    column :newsletter_added
    column :created_at
    column :processed_at
    column(:form_data) { |contact| contact.form_data.to_json }
  end

  # Sidebar stats
  sidebar 'Stats', only: :index do
    div class: 'panel_contents' do
      table do
        tr { [th('Total Contacts'), td(Contact.count)] }
        tr { [th('Last 24h'), td(Contact.last_24h.count)] }
        tr { [th('Pending'), td(Contact.pending.count)] }
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
