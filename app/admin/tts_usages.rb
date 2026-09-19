# frozen_string_literal: true

# Read-only: what POST /api/tts/briefing has been costing, and the limits that
# guard it (#199). The limits themselves are edited under Settings.
ActiveAdmin.register TtsUsage do
  menu label: 'TTS Usage', parent: 'Others', priority: 102

  actions :index, :show
  config.sort_order = 'created_at_desc'

  filter :status, as: :select, collection: TtsUsage::STATUSES
  filter :client_hash
  filter :created_at

  index do
    id_column
    column :status do |usage|
      status_tag usage.status
    end
    column :beats_count
    column :chars
    column('Synthesis (ms)', :synthesis_ms)
    column('Client', :client_hash)
    column :created_at
  end

  sidebar 'Limits', only: :index do
    para 'Edit under Settings; blank or 0 means the default.'
    table_for TtsUsage.limits do
      column('Setting key') { |limit| limit[:key] }
      column('Now') { |limit| limit[:value] }
      column('Default') { |limit| limit[:default] }
    end
  end

  sidebar 'Last 24 hours', only: :index do
    recent = TtsUsage.within(1.day)
    attributes_table_for(recent) do
      row('Briefings') { recent.count }
      row('Characters') { recent.sum(:chars) }
      row('Errors') { recent.where(status: 'error').count }
      row('In flight') { TtsUsage.in_flight.count }
    end
  end

  show do
    attributes_table do
      row :status do |usage|
        status_tag usage.status
      end
      row :beats_count
      row :chars
      row :synthesis_ms
      row :client_hash
      row :created_at
      row :updated_at
    end
  end
end
