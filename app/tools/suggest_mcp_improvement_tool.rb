# frozen_string_literal: true

class SuggestMcpImprovementTool < AuthenticatedTool
  tool_name 'suggest_mcp_improvement'

  description <<~MD
    Logs a request to improve an MCP tool, from this session. Call it
    yourself when you finish a task, without being asked, if a tool was
    missing, its output made you guess, or you needed a workaround. If the
    session went smoothly, don't call it.

    Not a to-do: it lands in the admin's MCP Suggestions section for triage.
  MD

  arguments do
    required(:friction).filled(:string)
                       .description('What broke or made you guess (concrete, not "this could be improved")')
    optional(:goal).filled(:string).description('What was being done in the session')
    optional(:proposal).filled(:string).description('How the tool should change, or what tool is missing')
    optional(:tools).filled(:string).description('Names of the tools involved, comma-separated')
  end

  def call(friction:, goal: nil, proposal: nil, tools: nil)
    suggestion = McpSuggestion.create!(friction: friction, goal: goal, proposal: proposal, tools: tools,
                                       reported_by: current_user)
    { status: 'logged', id: suggestion.id }.to_json
  end
end
