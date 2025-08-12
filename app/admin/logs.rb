# frozen_string_literal: true

ActiveAdmin.register Log do
  menu label: 'Logs', parent: 'Others', priority: 99

  filter :area, as: :select, collection: Log.areas.map { |key, value| [key.humanize, value] }
  filter :level, as: :select, collection: Log.levels.map { |key, value| [key.humanize, value] }
  filter :message
  filter :details
  filter :created_at

  actions :index, :show
end
