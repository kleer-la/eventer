# frozen_string_literal: true

require 'rails_helper'

# The cards of a concepts resource, loaded from Claude: upsert by slug + lang,
# _destroy to remove one, preview first and save on confirm.
RSpec.describe 'MCP resources: concepts operation', type: :request do
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
  let!(:resource) { create(:resource, format: :concepts, title_es: 'Conceptos de IA') }

  def call_tool(arguments)
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: 'resources', arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  def concepts(list, confirm: false)
    call_tool({ operation: 'concepts', id: resource.slug, concepts: list, confirm: })
  end

  let(:token) do
    { slug: 'token', name: 'Token', question: '¿Qué es un token?', stage: 'Qué pasa cuando le escribís',
      definition: 'La unidad en que el modelo lee y escribe.', related_slugs: ['contexto'] }
  end
  let(:contexto) do
    { slug: 'contexto', name: 'Ventana de contexto', stage: 'Qué pasa cuando le escribís',
      definition: 'Todo lo que el modelo tiene delante.', related_slugs: ['token'] }
  end

  it 'previews without saving, then creates cards that relate to each other in the same call' do
    preview = concepts([token, contexto])

    expect(preview['status']).to eq('preview')
    expect(preview['concepts'].map { |c| c.values_at('slug', 'action') }).to eq([%w[token create], %w[contexto create]])
    expect(ResourceConcept.count).to eq(0)

    saved = concepts([token, contexto], confirm: true)

    expect(saved['status']).to eq('saved')
    expect(resource.concepts.map { |c| [c.slug, c.lang, c.position, c.related] })
      .to eq([['token', 'es', 1, ['contexto']], ['contexto', 'es', 2, ['token']]])
  end

  it 'updates only the fields given, keyed by slug and language' do
    create(:resource_concept, resource:, slug: 'token', name: 'Token', practice: 'Viejo', position: 3)
    create(:resource_concept, resource:, slug: 'token', lang: 'en', name: 'Token', practice: 'Old')

    result = concepts([{ slug: 'token', practice: 'Todo se mide en tokens.' }], confirm: true)

    expect(result['concepts'].first).to include('action' => 'update')
    expect(result['concepts'].first['changes'].keys).to eq(['practice'])
    expect(ResourceConcept.find_by(slug: 'token', lang: 'es')).to have_attributes(
      practice: 'Todo se mide en tokens.', position: 3, name: 'Token'
    )
    expect(ResourceConcept.find_by(slug: 'token', lang: 'en').practice).to eq('Old')
  end

  it 'deletes a card with _destroy and warns about cards still pointing to it' do
    create(:resource_concept, resource:, slug: 'contexto')
    create(:resource_concept, resource:, slug: 'token', related_slugs: 'contexto')

    result = concepts([{ slug: 'contexto', _destroy: true }], confirm: true)

    expect(result['concepts'].first).to include('slug' => 'contexto', 'action' => 'destroy')
    expect(resource.concepts.pluck(:slug)).to eq(['token'])
    expect(result['warnings'].join).to include('token', 'contexto')
  end

  it 'saves nothing when one card relates to a concept that does not exist' do
    result = concepts([token.merge(related_slugs: %w[nada])], confirm: true)

    expect(result['status']).to eq('invalid')
    expect(result['errors'].join).to include('token', 'nada')
    expect(ResourceConcept.count).to eq(0)
  end

  it 'reports a new card missing what it needs' do
    result = concepts([{ slug: 'vacio', name: 'Vacío' }])

    expect(result['status']).to eq('invalid')
    expect(result['errors'].join).to include('vacio', 'Stage', 'Definition')
  end

  it 'warns when the resource is not of the concepts format' do
    resource.update!(format: :guide)

    expect(concepts([token.except(:related_slugs)])['warnings'].join).to include('concepts')
  end

  it 'shows the cards in get' do
    create(:resource_concept, resource:, slug: 'token', related_slugs: '')

    result = call_tool({ operation: 'get', id: resource.slug })

    expect(result['concepts'].first).to include('slug' => 'token', 'lang' => 'es', 'related_slugs' => [])
  end

  context 'with a content user' do
    let(:user) { create(:content_user) }

    it 'edits the text of a card but not its HTML media, nor deletes it' do
      create(:resource_concept, resource:, slug: 'token')

      expect(concepts([{ slug: 'token', practice: 'Nuevo' }], confirm: true)['status']).to eq('saved')
      expect(concepts([{ slug: 'token', media: '<div>x</div>' }])['errors'].join).to include('media')
      expect(concepts([{ slug: 'token', _destroy: true }])['errors'].join).to include('delete')
    end
  end
end
