ActiveAdmin.register Participant do
  menu parent: 'Courses Mgnt'
  belongs_to :event, optional: true

  # Configure default sort order
  config.sort_order = 'created_at_desc'

  controller do
    def scoped_collection
      participant_columns = %w[
        id created_at fname lname email phone address quantity status notes
        influence_zone_id event_id campaign_id campaign_source_id
        company_name id_number invoice_id xero_invoice_number is_payed
        selected testimony photo_url profile_url
        promoter_score event_rating trainer_rating trainer2_rating
        referer_code verification_code
      ].map { |col| "participants.#{col}" }

      super.includes(
        :influence_zone,
        { influence_zone: :country },
        { event: [:event_type] }
      ).select(participant_columns + [
        'influence_zones.zone_name',
        'influence_zones.tag_name',
        'countries.name as country_name',
        'events.date as event_date',
        'event_types.name as event_type_name'
      ]).joins(
        'LEFT JOIN influence_zones ON influence_zones.id = participants.influence_zone_id
         LEFT JOIN countries ON countries.id = influence_zones.country_id
         LEFT JOIN events ON events.id = participants.event_id
         LEFT JOIN event_types ON event_types.id = events.event_type_id'
      ).distinct
    end
  end
  # Keep existing search functionality
  filter :email
  filter :fname
  filter :lname
  filter :event, collection: lambda {
    Event.includes(:event_type)
         .order('date DESC')
         .limit(100)
         .pluck('events.date', 'event_types.name', 'events.id')
         .map do |date, name, id|
      event_type_name = name || 'No Event Type'
      ["#{date.strftime('%Y-%m-%d')} - #{event_type_name}", id]
    end
  }
  filter :status, as: :select, collection: Participant.status_collection_for_select
  filter :verification_code

  # Permit params for editing
  permit_params :email, :fname, :lname, :phone, :event_id, :status, :notes,
                :influence_zone_id, :quantity, :referer_code, :address,
                :company_name, :id_number, :invoice_id, :xero_invoice_number,
                :is_payed, :selected, :testimony, :photo_url, :profile_url,
                :accept_terms, :promoter_score, :event_rating, :trainer_rating,
                :trainer2_rating, :campaign_source, :campaign

  member_action :copy, method: :post do
    original_participant = resource
    # original_participant = Participant.find(resource.id)
    copies_to_create = [1, original_participant.quantity - 1].max

    ActiveRecord::Base.transaction do
      original_participant.quantity = 1
      original_participant.save!
      copies_to_create.times do
        new_participant = original_participant.dup
        new_participant.event = original_participant.event
        new_participant.save!
      end
    end

    redirect_to admin_event_path(original_participant.event),
                notice: "Successfully created #{copies_to_create} copies of participant"
  rescue StandardError => e
    redirect_to admin_event_path(original_participant.event),
                alert: "Error creating copies: #{e.message}"
  end

  index do
    selectable_column
    column :created_at do |participant|
      participant.created_at.strftime('%Y %b %d %H:%M')
    end
    column 'Event' do |participant|
      if participant.event
        event_type_name = participant.event.event_type&.name || 'No Event Type'
        link_to "#{participant.event.date.strftime('%Y-%m-%d')} - #{event_type_name}",
                admin_event_path(participant.event)
      else
        'No Event'
      end
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
        participant.status_label,
        style: "background-color: #{participant.status_color}"
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
    helper_method :icon_span

    private

    def icon_span(icon_name, text)
      "<span style='white-space:nowrap;'><i class='icon-#{icon_name}'></i> #{text}</span>".html_safe
    end
  end

  form do |f|
    influence_zones = InfluenceZone.includes(:country).order('countries.id, zone_name')
    events = Event.includes(:event_type)
                  .joins(:event_type)
                  .where.not(event_types: { name: nil })
                  .where('events.date > ?', 1.year.ago)
                  .order(date: :desc)

    tabs do
      tab 'General' do
        f.inputs do
          f.input :fname
          f.input :lname
          f.input :email
          f.input :phone
          f.input :address
          f.input :company_name
          f.input :id_number
          f.input :status, as: :select, collection: Participant.status_collection_for_select
          f.input :event, collection: events.map { |e|
            ["#{e.date.strftime('%Y-%m-%d')} - #{e.event_type.name}", e.id]
          },
                          include_blank: 'Selecciona uno...',
                          input_html: { style: 'width:500px' }
          f.input :influence_zone, collection: influence_zones.map { |z| [z.display_name, z.id] },
                                   include_blank: 'Tu lugar más próximo ...',
                                   hint: proc { |p| p.object.influence_zone&.tag_name || 'N/A' }
          f.input :quantity
          f.input :notes, input_html: { rows: 10 }
          f.input :referer_code
        end
      end

      tab 'Payment' do
        f.inputs do
          f.input :invoice_id, placeholder: '3cae5630-2189-4489-8464-b415e201da7d'
          f.input :xero_invoice_number, placeholder: 'FC-00000'
          f.input :is_payed
        end
      end

      tab 'Testimony' do
        f.inputs do
          f.input :selected
          f.input :testimony
          f.input :photo_url
          div class: 'photo-preview' do
            if f.object.photo_url.present?
              image_tag f.object.photo_url,
                        style: 'max-width: 300px; margin-top: 10px;'
            end
          end
          f.input :profile_url
          f.input :accept_terms
        end
      end

      tab 'NPS' do
        f.inputs do
          f.input :promoter_score
          f.input :event_rating
          f.input :trainer_rating
          f.input :trainer2_rating
        end
      end
    end
    f.actions
  end

  show do
    tabs do
      tab 'General' do
        attributes_table do
          row :fname
          row :lname
          row :email
          row :phone
          row :address
          row :company_name
          row :id_number
          row :status do |participant|
            status_tag(
              participant.status_label,
              style: "background-color: #{participant.status_color}"
            )
          end
          row :event
          row :influence_zone
          row :quantity
          row :notes
          row :referer_code
        end
      end

      tab 'Payment' do
        attributes_table do
          row :invoice_id
          row :xero_invoice_number
          row :is_payed
        end
      end

      tab 'Testimony' do
        attributes_table do
          row :selected
          row :testimony
          row :photo_url
          row :photo do |participant|
            if participant.photo_url.present?
              div class: 'photo-preview' do
                image_tag participant.photo_url, style: 'max-width: 300px;'
              end
            end
          end
          row :profile_url
          row :accept_terms
        end
      end

      tab 'NPS' do
        attributes_table do
          row :promoter_score
          row :event_rating
          row :trainer_rating
          row :trainer2_rating
        end
      end
    end
  end
end
