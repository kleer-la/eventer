# frozen_string_literal: true

class McpSuggestionsTool < AuthenticatedTool
  tool_name 'mcp_suggestions'
  requires_permission :manage, McpSuggestion

  description <<~MD
    Triage for suggest_mcp_improvement reports. Admin only.

    operation=list (default): by status, newest first. status: pending
    (default), tracked, done, dismissed or all.
    operation=triage: sets suggestion_id to status tracked (has an issue),
    done (fixed in code) or dismissed (won't do). resolution is required
    unless status is pending, which reopens it.
  MD

  arguments do
    optional(:operation).filled(:string).description("'list' (default) or 'triage'")
    optional(:status).filled(:string).description('list: filter (default pending; all = every status). ' \
                                                   'triage: the new status')
    optional(:limit).filled(:integer).description("list: max results (default #{DEFAULT_LIMIT}, max #{MAX_LIMIT})")
    optional(:suggestion_id).filled(:integer).description('triage: id of the suggestion')
    optional(:resolution).filled(:string).description('triage: issue, commit, or reason')
  end

  def call(operation: 'list', status: nil, limit: DEFAULT_LIMIT, suggestion_id: nil, resolution: nil)
    return triage(suggestion_id: suggestion_id, status: status, resolution: resolution) if operation == 'triage'

    list(status: status || 'pending', limit: limit)
  end

  private

  def list(status:, limit:)
    scope = McpSuggestion.order(created_at: :desc)
    scope = scope.where(status: status) unless status == 'all'

    items = scope.limit(limit.clamp(1, MAX_LIMIT)).map { |suggestion| summary(suggestion) }
    listing(:suggestions, items, total: scope.count, narrow: 'status')
  end

  def triage(suggestion_id:, status:, resolution:)
    return error('suggestion_id is required') if suggestion_id.nil?
    return error('status is required') if status.nil?
    return error('resolution is required unless status is pending') if status != 'pending' && resolution.blank?

    suggestion = McpSuggestion.find_by(id: suggestion_id)
    return error("No suggestion with id #{suggestion_id}") if suggestion.nil?

    suggestion.update!(status: status, resolution: resolution)
    { status: 'saved', id: suggestion.id, new_status: suggestion.status }.to_json
  end

  def summary(suggestion)
    { id: suggestion.id, status: suggestion.status, goal: suggestion.goal, friction: suggestion.friction,
      proposal: suggestion.proposal, tools: suggestion.tools, resolution: suggestion.resolution,
      reported_by: suggestion.reported_by&.email, created_at: suggestion.created_at }
  end

  def error(message) = { status: 'error', errors: [message] }.to_json
end
