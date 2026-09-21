# frozen_string_literal: true

require 'rails_helper'

# The contacts tool over MCP: what the site's forms sent in — a contact message,
# a resource download request, an assessment — findable by who and what, so
# "did X request session-handoff?" is one call.
RSpec.describe 'MCP contacts tool', type: :request do
  let(:user) { create(:administrator) }
  let(:oauth_application) do
    Doorkeeper::Application.create!(name: 'Claude', redirect_uri: 'https://claude.ai/api/mcp/auth_callback',
                                    scopes: 'mcp', confidential: false)
  end
  let(:headers) do
    token = Doorkeeper::AccessToken.create!(application: oauth_application, resource_owner_id: user.id,
                                            scopes: 'mcp', expires_in: 2.hours, use_refresh_token: true)
    { 'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json, text/event-stream',
      'HTTP_AUTHORIZATION' => "Bearer #{token.plaintext_token}" }
  end

  def call_tool(name, arguments = {})
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: name, arguments: arguments } }.to_json, headers: headers
    JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))
  end

  let!(:download) do
    Contact.create!(trigger_type: :download_form, email: 'Ana@Example.com',
                    form_data: { 'name' => 'Ana García', 'company' => 'Ejemplo SA', 'language' => 'en',
                                 'resource_slug' => 'session-handoff', 'newsletter_opt_in' => 'true' })
  end
  let!(:message) do
    Contact.create!(trigger_type: :contact_form, email: 'beto@example.com', created_at: 2.days.ago,
                    form_data: { 'name' => 'Beto', 'message' => 'Quiero un presupuesto', 'language' => 'es' })
  end

  describe 'operation=search (the default)' do
    it 'lists newest first with who, what and when, but not the form itself' do
      result = call_tool('contacts')

      expect(result['total']).to eq 2
      expect(result['contacts'].map { |c| c['email'] }).to eq ['Ana@Example.com', 'beto@example.com']
      expect(result['contacts'].first).to include('id' => download.id, 'trigger_type' => 'download_form',
                                                  'name' => 'Ana García', 'company' => 'Ejemplo SA',
                                                  'resource_slug' => 'session-handoff', 'language' => 'en',
                                                  'status' => 'pending')
      expect(result['contacts'].first).not_to have_key('form_data')
    end

    it 'finds by email or name, regardless of case' do
      expect(call_tool('contacts', { query: 'ana@example' })['contacts'].map { |c| c['id'] }).to eq [download.id]
      expect(call_tool('contacts', { query: 'beto' })['contacts'].map { |c| c['id'] }).to eq [message.id]
    end

    it 'filters by resource, trigger type and date' do
      expect(call_tool('contacts', { resource_slug: 'session-handoff' })['total']).to eq 1
      expect(call_tool('contacts', { resource_slug: 'otro' })['total']).to eq 0
      expect(call_tool('contacts', { trigger_type: 'contact_form' })['contacts'].map { |c| c['id'] }).to eq [message.id]
      expect(call_tool('contacts', { from: Date.current.to_s })['contacts'].map { |c| c['id'] }).to eq [download.id]
    end

    it 'names the trigger types when given one it does not know' do
      result = call_tool('contacts', { trigger_type: 'phone' })

      expect(result['status']).to eq 'error'
      expect(result['errors'].join).to include('download_form')
    end
  end

  describe 'operation=get' do
    it 'returns one contact with everything the form sent' do
      result = call_tool('contacts', { operation: 'get', id: message.id })

      expect(result['form_data']).to include('message' => 'Quiero un presupuesto')
      expect(result['email']).to eq 'beto@example.com'
    end

    it 'answers an error for one that does not exist' do
      expect(call_tool('contacts', { operation: 'get', id: 0 })['status']).to eq 'error'
    end
  end

  context 'as a content user' do
    let(:user) { create(:content_user) }

    it 'can search, like reading contacts in the admin' do
      expect(call_tool('contacts')['total']).to eq 2
    end
  end
end
