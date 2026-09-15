# frozen_string_literal: true

require 'rails_helper'

describe 'MCP suggestion tools' do
  let(:content_user) { FactoryBot.create(:content_user) }
  let(:admin) { FactoryBot.create(:administrator) }

  def run(tool_class, user, **args)
    tool = tool_class.new
    allow(tool).to receive_messages(current_user: user, ability: Ability.new(user))
    JSON.parse(tool.call(**args))
  end

  describe SuggestMcpImprovementTool do
    it 'logs a suggestion from any authenticated user' do
      result = run(described_class, content_user, friction: 'No tool for X', goal: 'Doing Y',
                                                  proposal: 'Add a tool for X', tools: 'get_x, list_x')

      suggestion = McpSuggestion.find(result['id'])
      expect(suggestion.friction).to eq 'No tool for X'
      expect(suggestion.reported_by).to eq content_user
      expect(suggestion.status).to eq 'pending'
    end
  end

  describe McpSuggestionsTool do
    let!(:suggestion) { McpSuggestion.create!(friction: 'No tool for X', reported_by: content_user) }

    it 'is admin only' do
      tool = described_class.new
      allow(tool).to receive_messages(current_user: content_user, ability: Ability.new(content_user))

      expect(tool.authorized?).to be false
    end

    it 'authorizes an administrator' do
      tool = described_class.new
      allow(tool).to receive_messages(current_user: admin, ability: Ability.new(admin))

      expect(tool.authorized?).to be true
    end

    it 'lists pending suggestions by default' do
      result = run(described_class, admin)

      expect(result['suggestions'].map { |s| s['id'] }).to eq [suggestion.id]
    end

    it 'triages a suggestion' do
      result = run(described_class, admin, operation: 'triage', suggestion_id: suggestion.id,
                                           status: 'tracked', resolution: '#123')

      expect(result['status']).to eq 'saved'
      expect(suggestion.reload.status).to eq 'tracked'
      expect(suggestion.resolution).to eq '#123'
    end

    it 'requires a resolution unless reopening to pending' do
      result = run(described_class, admin, operation: 'triage', suggestion_id: suggestion.id, status: 'dismissed')

      expect(result['status']).to eq 'error'
      expect(suggestion.reload.status).to eq 'pending'
    end
  end
end
