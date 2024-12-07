ActiveAdmin.register Participant do
  menu parent: 'Courses Mgnt'
  belongs_to :event, optional: true

  # Keep existing search functionality
  filter :email
  filter :fname
  filter :lname
  filter :event, collection: lambda {
    Event.all.map { |e| ["#{e.date.strftime('%Y-%m-%d')} - #{e.event_type.name}", e.id] }
         .sort.reverse
  }
  filter :status
  filter :verification_code

  # Permit params for editing
  permit_params :email, :fname, :lname, :phone, :event_id, :status, :notes,
                :influence_zone_id, :quantity, :referer_code, :address

  # Index page customization
  index do
    selectable_column
    column :created_at
    column 'Event' do |participant|
      "#{participant.event.date.strftime('%Y-%m-%d')} - #{participant.event.event_type.name}"
    end
    column 'Name' do |participant|
      icon_span('user', "#{participant.fname} #{participant.lname}")
    end
    column 'Email' do |participant|
      icon_span('envelope-alt', participant.email)
    end
    column 'Qty' do |participant|
      icon_span('list', participant.quantity.to_s)
    end

    column 'Contact Info' do |participant|
      div do
        icon_span('phone-sign', participant.phone)
      end
      div do
        icon_span('globe', participant.influence_zone&.display_name)
      end
      div do
        icon_span('tag', participant.influence_zone&.tag_name || 'N/A')
      end
      div do
        icon_span('home', participant.address)
      end
    end

    column :status do |participant|
      status_tag(
        status_text(participant.status),
        class: participant_status_class(participant.status)
      )
    end

    column :notes

    actions do |participant|
      if 'AK'.include?(participant.status)
        item 'Certificate', certificate_admin_participant_path(participant), class: 'member_link'
      end
    end
  end

  # Custom action for certificate
  member_action :certificate, method: :get do
    participant = Participant.find(params[:id])
    # Add certificate generation logic here
    redirect_to admin_participant_path(participant), notice: 'Certificate generated'
  end

  # Helper methods
  controller do
    helper_method :icon_span, :status_text, :participant_status_class

    private

    def participant_status_class(status)
      case status
      when 'N' then 'error'
      when 'T' then 'warning'
      when 'C' then 'info'
      when 'A' then 'success'
      when 'K' then 'success'
      when 'X' then 'warning'
      when 'D' then 'warning'
      else 'error'
      end
    end

    def status_text(status)
      case status
      when 'N' then 'Nuevo'
      when 'T' then 'Contactado'
      when 'C' then 'Confirmado'
      when 'A' then 'Presente'
      when 'K' then 'Certificado'
      when 'X' then 'Cancelado'
      when 'D' then 'Pospuesto'
      else 'Desconocido'
      end
    end

    def icon_span(icon_name, text)
      "<span style='white-space:nowrap;'><i class='icon-#{icon_name}'></i> #{text}</span>".html_safe
    end
  end
end
