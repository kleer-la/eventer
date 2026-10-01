# frozen_string_literal: true

require 'rails_helper'

# QA should look like production when testing an article (#216): copy one by
# slug from production's public API, with what it links to that QA also has.
RSpec.describe 'MCP articles: copy_from_production', type: :request do
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
  let(:production) do
    { 'slug' => 'preguntas-ia', 'title' => 'Preguntas para la IA', 'tabtitle' => 'Preguntas IA',
      'description' => 'Qué preguntarse', 'body' => 'El **cuerpo** con ![x](https://kleer-images.s3.sa-east-1.amazonaws.com/x.png)',
      'lang' => 'es', 'published' => true, 'selected' => true, 'noindex' => false, 'industry' => 'technology',
      'cover' => 'https://kleer-images.s3.sa-east-1.amazonaws.com/portada.jpg', 'header' => '', 'redirect_url' => nil,
      'category_name' => 'Negocios', 'id' => 1044, 'audio' => 'https://kleer-images.s3.sa-east-1.amazonaws.com/a.mp3',
      'trainers' => [{ 'name' => 'Ana Autora' }, { 'name' => 'Solo En Prod' }],
      'recommended' => [{ 'type' => 'resource', 'slug' => 'kartas', 'relevance_order' => 10 },
                        { 'type' => 'article', 'slug' => 'no-esta-en-qa', 'relevance_order' => 20 }] }
  end

  def call_tool(arguments)
    post '/mcp', params: { jsonrpc: '2.0', method: 'tools/call', id: 1,
                           params: { name: 'articles', arguments: arguments } }.to_json, headers: headers
    raw = response.parsed_body.dig('result', 'content', 0, 'text')
    raw.present? ? JSON.parse(raw) : response.parsed_body
  end

  def copy(confirm: false) = call_tool({ operation: 'copy_from_production', id: 'preguntas-ia', confirm: })

  let!(:category) { create(:category, name: 'Negocios') }
  let!(:ana) { create(:trainer, name: 'Ana Autora') }
  let!(:kartas) { create(:resource, slug: 'kartas') }

  before do
    stub_const('ENV', ENV.to_h.merge('PRODUCTION_API_URL' => 'https://eventos.kleer.la'))
    stub_request(:get, 'https://eventos.kleer.la/api/articles/preguntas-ia')
      .to_return(body: production.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'previews the copy and what it cannot bring, without saving' do
    result = copy

    expect(result['status']).to eq('preview')
    expect(result['changes']).to include('title', 'body', 'trainers')
    expect(result['recommendations']).to eq('link' => ['resource kartas'], 'missing' => ['article no-esta-en-qa'])
    expect(result['warnings'].join).to include('Solo En Prod')
    expect(Article.count).to eq(0)
  end

  it 'creates it on confirm, with its category, the authors and recommendations QA has' do
    result = copy(confirm: true)

    article = Article.find_by(slug: 'preguntas-ia')
    expect(result['status']).to eq('saved')
    expect(article).to have_attributes(title: 'Preguntas para la IA', published: true, industry: 'technology',
                                       cover: production['cover'], category: category)
    expect(article.trainers).to eq [ana]
    expect(article.recommended_contents.map { |r| [r.target, r.relevance_order] }).to eq [[kartas, 10]]
  end

  it 'updates the QA article with that slug, keeping one link per recommendation' do
    existing = create(:article, slug: 'preguntas-ia', title: 'Viejo')
    existing.recommended_contents.create!(target: kartas, relevance_order: 50)

    copy(confirm: true)

    expect(existing.reload.title).to eq('Preguntas para la IA')
    expect(existing.recommended_contents.map { |r| [r.target, r.relevance_order] }).to eq [[kartas, 10]]
    expect(Article.count).to eq(1)
  end

  it 'says so when production has no such article' do
    stub_request(:get, 'https://eventos.kleer.la/api/articles/preguntas-ia').to_return(status: 404)

    expect(copy['errors'].join).to include('preguntas-ia', '404')
  end

  it 'is only there where production is configured as a source' do
    stub_const('ENV', ENV.to_h.except('PRODUCTION_API_URL'))

    expect(copy['errors'].join).to include('QA')
  end
end
