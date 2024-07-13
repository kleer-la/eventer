# frozen_string_literal: true

ActiveAdmin.register Log do
  menu label: 'Logs', parent: 'Others', priority: 99

  filter :area
  filter :level
  filter :message
  filter :details
  filter :created_at

  actions :index, :show
end
