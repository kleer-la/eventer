# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: 'Dashboard'

  content title: 'Dashboard' do
    columns do
      column do # left column
        panel 'Alertas Admin' do
          event_project_code_alert
          event_type_project_code_alert
        end
        panel 'Alertas Contenido' do
          cover_alert
          brochure_alert
          event_type_project_code_alert
        end
      end
      column do # right column
        panel 'Próximos cursos' do
          grouped_events.each do |period, events|
            h4 period, class: 'period-group'
            table_for events, class: 'no-table-headings' do
              column :human_date
              column nil do |event|
                human_hours = event.start_time.strftime('%H:%Mhs.')
                trainers = event.trainers.pluck(:name).join(',')
                link_to "#{event.event_type.name} - #{event.date} | #{event.city} | #{human_hours} | #{event.place} | #{trainers}",
                        admin_event_path(event)
              end
              column(nil, class: 'cell-semaphore') do |event|
                confirmed_rate = event.confirmed_quantity.to_f / event.capacity
                if event.registration_link.blank?
                  color = (confirmed_rate / 0.25).floor
                  class_name = "status-#{color}"
                  div class: class_name do
                    "#{(confirmed_rate * 100).round}% (#{event.confirmed_quantity}/#{event.capacity}) "
                  end
                end
              end
            end
          end
        end
        panel 'Precios Próximos Eventos' do
          pricing_events.each do |event|
            table_for [event], class: 'no-table-headings pricing-table' do
              column :fecha do |e|
                span e.human_date, class: 'event-date'
              end
              column :evento do |e|
                div do
                  div do
                    link_to e.event_type&.name || 'Sin Tipo', admin_event_path(e), class: 'event-name'
                  end
                  div do
                    span e.city, class: 'event-city'
                  end
                end
              end
              column 'Precios Individuales' do |e|
                div class: 'individual-pricing' do
                  if e.list_price&.positive?
                    div class: 'price-item' do
                      span 'Lista: ', class: 'price-label'
                      span "#{currency_symbol_for(e.currency_iso_code)}#{format('%.2f', e.list_price)} (#{e.currency_iso_code})",
                           class: 'price-value'
                    end
                    if e.eb_price&.positive?
                      div class: 'price-item' do
                        span 'EB: ', class: 'price-label'
                        span "#{currency_symbol_for(e.currency_iso_code)}#{format('%.2f', e.eb_price)}",
                             class: 'price-value'
                        br
                        span "hasta #{e.eb_end_date&.strftime('%d/%m')}", class: 'price-date'
                      end
                    end
                    if e.couples_eb_price&.positive?
                      div class: 'price-item' do
                        span 'EB Parejas: ', class: 'price-label'
                        span "#{currency_symbol_for(e.currency_iso_code)}#{format('%.2f', e.couples_eb_price)}",
                             class: 'price-value'
                        br
                        span "hasta #{e.eb_end_date&.strftime('%d/%m')}", class: 'price-date'
                      end
                    end
                  else
                    span 'Gratuito', class: 'free-event'
                  end
                end
              end
              column 'Precios Grupales' do |e|
                div class: 'group-pricing' do
                  if e.business_price&.positive?
                    div class: 'price-item' do
                      span 'Business: ', class: 'price-label'
                      span "#{currency_symbol_for(e.currency_iso_code)}#{format('%.2f', e.business_price)}",
                           class: 'price-value'
                    end
                  end
                  if e.business_eb_price&.positive?
                    div class: 'price-item' do
                      span 'Business EB: ', class: 'price-label'
                      span "#{currency_symbol_for(e.currency_iso_code)}#{format('%.2f', e.business_eb_price)}",
                           class: 'price-value'
                      br
                      span "hasta #{e.eb_end_date&.strftime('%d/%m')}", class: 'price-date'
                    end
                  end
                  if !e.business_price&.positive? && !e.business_eb_price&.positive?
                    span '-', class: 'no-group-pricing'
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

def brochure_alert
  event_type_alert('Event Type sin brochure',
                   EventType.where(include_in_catalog: true, deleted: false, brochure: [nil, ''], platform: :keventer))
end

def cover_alert
  event_type_alert('Event Type sin cover',
                   EventType.where(include_in_catalog: true, deleted: false, cover: [nil, '']))
end

def event_project_code_alert
  event_type_alert(
    'Cursos abiertos sin código proyecto (Event )',
    Event.public_and_visible.where(online_cohort_codename: [nil, ''])
  )
end

def event_type_project_code_alert
  event_type_alert(
    'Event Type sin código projecto',
    EventType.where(include_in_catalog: true, tag_name: [nil, ''], platform: :keventer)
  )
end

def event_type_alert(message, error_list)
  return if error_list.count.zero?

  h4 "#{message} (#{error_list.count})"
  ul do
    error_list.each do |et|
      li link_to(et.name, edit_event_type_path(et))
    end
  end
end

def dweek(d)
  (d.year * 100 + d.cweek) - (Date.today.year * 100 + Date.today.cweek)
end

def grouped_events
  events = Event.public_and_visible.order('date').select do |ev|
    !ev.event_type.nil? && ev.registration_link == ''
  end

  {
    'Up to 2 Weeks' => events.select { |ev| dweek(ev.date) <= 2 },
    '2-4 Weeks' => events.select { |ev| dweek(ev.date).between?(3, 4) },
    '4-6 Weeks' => events.select { |ev| dweek(ev.date).between?(5, 6) },
    '6+ Weeks' => events.select { |ev| dweek(ev.date) > 6 }
  }
end

def pricing_events
  Event.public_commercial_visible.order(:date)
       .where.not(event_type_id: nil)
       .where(registration_link: '')
       .limit(10) # Show only next 10 events for dashboard
end

def currency_symbol_for(currency_code)
  case currency_code
  when 'USD'
    '$'
  when 'EUR'
    '€'
  when 'ARS'
    '$'
  when 'COP'
    '$'
  when 'PEN'
    'S/'
  when 'BOB'
    'Bs'
  else
    currency_code
  end
end
