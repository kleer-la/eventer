# frozen_string_literal: true

ActiveAdmin.register McpSuggestion do
  menu label: 'MCP Suggestions', parent: 'Others', priority: 101

  permit_params :status, :resolution

  actions :index, :show, :edit, :update

  filter :status, as: :select, collection: McpSuggestion.statuses.keys
  filter :tools
  filter :created_at

  index do
    selectable_column
    id_column
    column :status do |suggestion|
      status_tag suggestion.status
    end
    column :goal
    column :friction
    column :tools
    column :reported_by
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :status do |suggestion|
        status_tag suggestion.status
      end
      row :goal
      row :friction
      row :proposal
      row :tools
      row :resolution
      row :reported_by
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    para link_to('View the full suggestion', admin_mcp_suggestion_path(f.object))
    f.inputs 'Triage' do
      f.input :status, as: :select, collection: McpSuggestion.statuses.keys
      f.input :resolution, hint: 'Issue number, commit, or reason. Required unless status is pending.'
    end
    f.actions
  end
end
