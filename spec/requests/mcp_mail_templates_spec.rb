# frozen_string_literal: true

require 'rails_helper'

# The mail_templates tool over MCP — one tool, four operations — for the emails
# the site's forms trigger: readable with a rendered sample, editable with the
# same preview/confirm as content.
RSpec.describe 'MCP mail_templates tool', type: :request do
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
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  let!(:generic) do
    create(:mail_template, identifier: 'descarga_recurso', trigger_type: 'download_form', lang: :es,
                           subject: 'Descarga de {{resource_title_es}}', to: '{{email}}',
                           content: 'Hola {{name | split: " " | first}}, <a href="{{resource_getit_es}}">Descargar</a>')
  end
  let!(:own) do
    create(:mail_template, identifier: 'session_handoff_en', trigger_type: 'download_form', lang: :en,
                           resource_slug: 'session-handoff', subject: 'Your access', to: '{{email}}',
                           content: 'Go to {{resource_getit_en}}')
  end

  describe 'operation=list (the default)' do
    it 'lists them with what decides when they are sent, and filters' do
      result = call_tool('mail_templates')
      expect(result['total']).to eq 2
      expect(result['templates'].first.keys).to include('id', 'identifier', 'trigger_type', 'lang', 'resource_slug',
                                                        'subject', 'to', 'active', 'delivery_schedule')

      expect(call_tool('mail_templates', { operation: 'list', resource_slug: 'session-handoff' })['templates']
               .map { |t| t['identifier'] }).to eq ['session_handoff_en']
      expect(call_tool('mail_templates', { operation: 'list', lang: 'es' })['templates'].map { |t| t['identifier'] })
        .to eq ['descarga_recurso']
    end
  end

  describe 'operation=get' do
    it 'returns the template and how it renders for a sample contact' do
      result = call_tool('mail_templates', { operation: 'get', id: 'descarga_recurso' })

      expect(result['content']).to include('{{resource_getit_es}}')
      expect(result['rendered']['subject']).to eq 'Descarga de Recurso de ejemplo'
      expect(result['rendered']['content']).to include('Hola Ana', 'href="https://')
      expect(result['rendered']['to']).to eq 'ana@example.com'
    end

    it 'renders with a real resource when given its slug' do
      create(:resource, slug: 'guia-x', title_es: 'Guía X', getit_es: 'https://files.example/guia-x.pdf')

      result = call_tool('mail_templates', { operation: 'get', id: generic.id.to_s, resource_slug: 'guia-x' })

      expect(result['rendered']['subject']).to eq 'Descarga de Guía X'
      expect(result['rendered']['content']).to include('https://files.example/guia-x.pdf')
    end

    it 'answers an error for one that does not exist' do
      expect(call_tool('mail_templates', { operation: 'get', id: 'nope' })['status']).to eq 'error'
    end
  end

  describe 'operation=update' do
    it 'previews, then saves on confirm, and patches content with replacements' do
      result = call_tool('mail_templates',
                         { operation: 'update', id: 'descarga_recurso', subject: 'Tu descarga' })
      expect(result['status']).to eq 'preview'
      expect(generic.reload.subject).to eq 'Descarga de {{resource_title_es}}'

      result = call_tool('mail_templates',
                         { operation: 'update', id: 'descarga_recurso', subject: 'Tu descarga', confirm: true,
                           replacements: [{ field: 'content', find: 'Descargar', replace: 'Bajar el recurso' }] })
      expect(result['status']).to eq 'saved'
      expect(generic.reload).to have_attributes(subject: 'Tu descarga')
      expect(generic.content).to include('Bajar el recurso')
    end

    it 'warns when a Liquid variable in the content is not one the form provides' do
      result = call_tool('mail_templates',
                         { operation: 'update', id: 'descarga_recurso', content: 'Hola {{nombre}}' })

      expect(result['warnings'].join).to include('nombre')
    end

    it 'can clear the resource slug, making the template generic again' do
      call_tool('mail_templates',
                { operation: 'update', id: 'session_handoff_en', resource_slug: '', confirm: true })

      expect(own.reload.resource_slug).to eq ''
    end

    context 'as a content user' do
      let(:user) { create(:content_user) }

      it 'can read but not write' do
        expect(call_tool('mail_templates', { operation: 'get', id: 'descarga_recurso' })['content']).to be_present
        result = call_tool('mail_templates',
                           { operation: 'update', id: 'descarga_recurso', subject: 'x', confirm: true })
        expect(result['status']).to eq('error')
        expect(result['errors'].join).to match(/not allowed/i)
      end
    end
  end

  it 'names the operations it knows when given another' do
    result = call_tool('mail_templates', { operation: 'send' })

    expect(result['status']).to eq('error')
    expect(result['errors'].join).to include('list', 'get', 'update', 'create')
  end

  describe 'operation=create' do
    it 'creates a template of a resource own, unpublished until active' do
      result = call_tool('mail_templates',
                         { operation: 'create', identifier: 'session_handoff_es', trigger_type: 'download_form',
                           lang: 'es', resource_slug: 'session-handoff', subject: 'Tu acceso', to: '{{email}}',
                           content: 'Entrá en {{resource_getit_es}} con {{email}}', confirm: true })

      expect(result['status']).to eq 'saved'
      template = MailTemplate.find_by(identifier: 'session_handoff_es')
      expect(template).to have_attributes(trigger_type: 'download_form', lang: 'es', resource_slug: 'session-handoff',
                                          active: true, delivery_schedule: 'immediate')
    end

    it 'reports validation errors instead of saving' do
      result = call_tool('mail_templates',
                         { operation: 'create', identifier: 'descarga_recurso', trigger_type: 'download_form',
                           lang: 'es', subject: 'x', to: '{{email}}', content: 'y', confirm: true })

      expect(result['status']).to eq 'error'
      expect(result['errors'].join).to match(/identifier/i)
    end
  end
end
