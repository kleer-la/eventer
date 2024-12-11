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

  member_action :download_participants, method: :get do
    event = Event.find(params[:id])
    participants = event.participants.includes(:influence_zone, influence_zone: :country)

    send_data participants.to_comma,
              filename: "participants-#{event.date.strftime('%Y-%m-%d')}-#{event.event_type.name.parameterize}.csv",
              type: 'text/csv'
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
        div class: 'header-with-actions' do
          div class: 'title-section' do
            h2 "#{event.date.to_formatted_s(:short)} - #{event.city}", style: 'margin: 0; display: inline-block;'
          end
          div class: 'action-section', style: 'display: inline-block;' do
            span style: 'margin: 0 5px;' do
              link_to 'Download CSV', download_participants_admin_event_path(event, format: 'csv'),
                      class: 'button-default'
            end
            span style: 'margin: 0 5px;' do
              link_to 'Generate Certificates',
                      "/events/#{event.id}/send_certificate",
                      # send_certificate_event_path(event),
                      class: 'button-default',
                      data: {
                        confirm: "¡Atención!

Esta operación enviará certificados de asistencia SOLO a las #{event.attended_quantity + event.participants.certified.count} personas  que están 'Presente' o 'Certificados'.
Antes de seguir, asegúrate que el evento ya haya finalizado, que las personas que participaron estén marcadas como 'Presente' y que quienes estuvieron ausentes estén marcados como 'Postergado' o 'Cancelado'.
"
                      }
            end
          end
        end

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

        render partial: '/admin/events/participants_panel', locals: { event: }
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
        end
      end
    end
  end
end
