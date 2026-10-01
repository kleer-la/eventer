# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Concepts in /api/resources/:id', type: :request do
  let(:resource) { create(:resource, format: :concepts, title_es: 'Conceptos de IA sin jerga') }

  def concept(attrs = {})
    create(:resource_concept, { resource: }.merge(attrs))
  end

  def show(lang = 'es')
    get "/api/resources/#{resource.slug}", params: { lang: }
    JSON.parse(response.body)
  end

  it 'lists the concepts of the requested language in reading order, with every field' do
    concept(slug: 'contexto', name: 'Ventana de contexto', position: 2, stage: 'Qué pasa cuando le escribís')
    concept(slug: 'token', name: 'Token', position: 1, stage: 'Qué pasa cuando le escribís',
            question: '¿Qué es un token?', definition: 'La unidad en que el modelo lee.',
            analogy: 'Sílabas.', misconception: 'Lee letra por letra.', correction: 'Ve pedazos.',
            practice: 'Todo se mide en tokens.', media: '<div class="toks">…</div>', related_slugs: 'contexto')
    concept(slug: 'token', name: 'Token', position: 1, lang: 'en', stage: 'What happens when you write')

    json = show

    expect(json['concepts'].pluck('slug')).to eq(%w[token contexto])
    expect(json['concepts'].first).to include(
      'lang' => 'es', 'position' => 1, 'name' => 'Token', 'question' => '¿Qué es un token?',
      'stage' => 'Qué pasa cuando le escribís', 'definition' => 'La unidad en que el modelo lee.',
      'analogy' => 'Sílabas.', 'misconception' => 'Lee letra por letra.', 'correction' => 'Ve pedazos.',
      'practice' => 'Todo se mide en tokens.', 'media' => '<div class="toks">…</div>',
      'related_slugs' => ['contexto']
    )
    expect(json['concepts'].first).to include('updated_at')
    expect(show('en')['concepts'].pluck('stage')).to eq(['What happens when you write'])
  end

  it 'leaves concepts out of resources of other formats' do
    card = create(:resource, format: :card)

    get "/api/resources/#{card.slug}", params: { lang: 'es' }

    expect(JSON.parse(response.body)).not_to have_key('concepts')
  end

  it 'answers an empty list for a concepts resource without concepts' do
    expect(show['concepts']).to eq([])
  end
end
