# frozen_string_literal: true

ActiveAdmin.register Event do
  menu parent: 'Courses Mgnt'

  Event.attribute_names.each do |attribute|
    filter attribute.to_sym
  end

  scope :all, default: false
  scope 'Current', :visible, default: true

  action_item :view_old_version, only: :index do
    link_to 'Old version', events_path, class: 'button'
  end

  index do
    column :date
    column 'Tipo evento', :event_type do |event|
      event.event_type&.name
    end
    column 'Detalles', :event_type do |event|
      content = []

      if event.country.present?
        content << content_tag(:i, '', class: "flag flag-#{event.country.iso_code.downcase}")
        content << event.city
      end

      time_and_place = [
        event.start_time.strftime('%H:%Mhs.'),
        event.place,
        (event.address unless event.address == 'Online')
      ].compact.join(', ')

      content << content_tag(:br) + time_and_place

      content.join(' ').html_safe
    end
    column 'Visibilidad', :event_type do |event|
      { 'pu' => 'Publico', 'pr' => 'Privado', 'co' => 'Comunidad' }[event.visibility_type]
    end
    column :draft
    column :cancelled
    column :is_sold_out
    actions defaults: false do |event|
      item link_to('Participantes', admin_event_path(event))
      text_node ' | '
      item link_to('Editar', edit_admin_event_path(event))
      text_node ' | '
      item link_to('Copiar', copy_event_path(event))
    end
  end

  show do
    tabs do
      tab 'Participants' do
        panel 'Event Statistics', class: 'stats-panel' do
          div class: 'stat-columns' do
            div class: 'stat-item' do
              span "Completion: #{(event.completion * 100).round}%"
              br
              span "#{event.seat_available} seats remaining"
            end

            div class: 'stat-item' do
              span 'New'
              br
              span event.new_ones_quantity
            end

            div class: 'stat-item' do
              span 'Contacted'
              br
              span event.contacted_quantity
            end

            div class: 'stat-item' do
              span 'Confirmed'
              br
              span event.confirmed_quantity
            end

            div class: 'stat-item' do
              span 'Present'
              br
              span event.attended_quantity
            end
          end
        end

        panel 'Participants List' do
          table_for event.participants do
            column :created_at do |p|
              p.created_at.strftime('%Y-%m-%d %H:%M')
            end
            column 'Participant' do |p|
              "#{p.fname} #{p.lname} (#{p.email}) - Qty: #{p.quantity}"
            end

            column 'Contact Info' do |p|
              "#{p.phone} - #{p.influence_zone&.display_name} - #{p.address}"
            end

            column :status do |p|
              status_color = {
                'N' => '#f34541',
                'T' => '#9564e2',
                'C' => '#00acec',
                'A' => '#49bf67',
                'K' => '#00b0b0',
                'X' => '#f8a326',
                'D' => '#f8a326'
              }

              div style: "background-color: #{status_color[p.status]}; color: white; padding: 3px 6px; border-radius: 3px;" do
                best_in_place p, :status,
                              as: :select,
                              url: "/events/#{p.event.id}/participants/#{p.id}",
                              collection: Participant::STATUS_OPTIONS
              end
            end

            column :notes

            column 'Actions' do |p|
              links = []
              links << link_to('Edit', edit_admin_event_participant_path(p.event, p))
              links << link_to('Copy', copy_admin_event_participant_path(p.event, p),
                               method: :post,
                               data: { confirm: "Create #{[1, p.quantity - 1].max} copies?" })
              if 'AK'.include?(p.status)
                links << link_to('Certificate', "/events/#{p.event.id}/participants/#{p.id}/certificate.pdf")
              end
              links.join(' | ').html_safe
            end
          end
        end
      end

      tab 'Event Details' do
        attributes_table do
          row :event_type
          row :date
          row :finish_date
          row :registration_ends
          row :capacity
          row :duration
          row :start_time
          row :end_time
          row :mode
          row :time_zone_name
          row :place
          row :address
          row :city
          row :country
          row :trainer
          row :trainer2
          row :trainer3
          row :visibility_type
          row :currency_iso_code
          row :list_price
          row :business_price
          row :enterprise_6plus_price
          row :enterprise_11plus_price
          # Add other fields as needed
        end
      end
    end
  end
end
