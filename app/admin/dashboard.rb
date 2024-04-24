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
      column do # left column
        panel 'Próximos cursos' do
          grouped_events.each do |period, events|
            h4 period, class: 'period-group'
            table_for events, class: 'no-table-headings' do
              column :human_date
              column nil do |event|
                human_hours = event.start_time.strftime( "%H:%Mhs." )
                trainers = event.trainers.pluck(:name).join(',')
                link_to "#{event.event_type.name} - #{event.date} | #{event.city} | #{human_hours} | #{event.place} | #{trainers}",
                        event_participants_path(event)
              end
              column(nil, class: 'cell-semaphore') do |event|
                if event.registration_link.blank?
                  color = %w(red yellow green)[ (event.completion / 33).floor]
                  class_name = "status-#{color}"
                  div class: class_name do
                    "#{(event.completion * 100).round}% (#{event.confirmed_quantity}/#{event.capacity}) "
                  end
                end
              end
            end
          end
        end
      end
    end

    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end # content
end

def brochure_alert
  event_type_alert('Event Type sin brochure', 
    EventType.where(include_in_catalog: true, deleted: false, brochure: [nil, ''], platform: :keventer)
  )
end

def cover_alert
  event_type_alert('Event Type sin cover', 
    EventType.where(include_in_catalog: true, deleted: false, cover: [nil, ''])
  )
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
  return if error_list.count() == 0

  h4 "#{message} (#{error_list.count})"
  ul do
    error_list.each do |et|
      li link_to(et.name, edit_event_type_path(et))
    end
  end
end

def dweek(d)
  (d.year * 100 + d.cweek) - (Date.today.year*100+Date.today.cweek)
end

def grouped_events
  events = Event.public_and_visible.order('date').select do |ev|
    !ev.event_type.nil? && ev.registration_link == ''
  end

  {
    'Up to 2 Weeks' => events.select{ |ev| dweek(ev.date)<=2 },
    '2-4 Weeks' => events.select{ |ev| dweek(ev.date).between?(3,4) },
    '4-6 Weeks' => events.select{ |ev| dweek(ev.date).between?(5,6) },
    '6+ Weeks' => events.select{ |ev| dweek(ev.date)>6 }
  }
end
