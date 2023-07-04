# frozen_string_literal: true
ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: 'Dashboard'

  content title: 'Dashboard' do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    columns do
      column do # left column
        panel 'Alertas' do
          cover_alert
          brochure_alert
          event_type_project_code_alert
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
    EventType.where(include_in_catalog: true, deleted: false, brochure: [nil, ''])
  )
end

def cover_alert
  event_type_alert('Event Type sin cover', 
    EventType.where(include_in_catalog: true, deleted: false, cover: [nil, ''])
  )
end

def event_type_project_code_alert
  event_type_alert('Event Type sin código projecto', 
    EventType.where(include_in_catalog: true, tag_name: [nil, ''])
  )
end

def event_type_alert(message, error_list)
  return if (error_list.count() == 0)

  h4 "#{message} (#{error_list.count})"
  ul do
    error_list.each do |et|
      li link_to(et.name, edit_event_type_path(et))
    end
  end
end
