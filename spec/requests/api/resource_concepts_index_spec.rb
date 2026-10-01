# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Concept slugs in /api/resources', type: :request do
  let!(:glossary) { create(:resource, format: :concepts) }
  let!(:card) { create(:resource, format: :card) }

  before do
    create(:resource_concept, resource: glossary, slug: 'token', position: 1)
    create(:resource_concept, resource: glossary, slug: 'agente', position: 2)
    create(:resource_concept, resource: glossary, slug: 'token', lang: 'en', position: 1)
  end

  %w[/api/resources /api/resources/preview].each do |path|
    it "#{path} lists slug, language and date of the concepts, only for concepts resources" do
      get path

      json = JSON.parse(response.body).index_by { |r| r['id'] }
      expect(json[glossary.id]['concepts'].map { |c| c.values_at('slug', 'lang') })
        .to contain_exactly(%w[token es], %w[agente es], %w[token en])
      expect(json[glossary.id]['concepts'].first.keys).to contain_exactly('slug', 'lang', 'updated_at')
      expect(json[card.id]).not_to have_key('concepts')
    end
  end

  it 'loads the concepts of every resource in one query' do
    other = create(:resource, format: :concepts)
    create(:resource_concept, resource: other)

    queries = []
    counter = ->(*, payload) { queries << payload[:sql] if payload[:sql].include?('resource_concepts') }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { get '/api/resources' }

    expect(queries.size).to eq(1)
  end
end
