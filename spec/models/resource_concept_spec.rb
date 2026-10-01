# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceConcept do
  let(:resource) { create(:resource, format: :concepts) }

  it 'is valid from the factory' do
    expect(build(:resource_concept, resource:)).to be_valid
  end

  it 'needs a name, a language, a stage and a definition' do
    concept = described_class.new(resource:, lang: 'fr')

    expect(concept).not_to be_valid
    expect(concept.errors.attribute_names).to include(:name, :lang, :stage, :definition)
  end

  it 'makes the slug from the name' do
    concept = create(:resource_concept, resource:, slug: nil, name: 'Predicción del próximo token')

    expect(concept.slug).to eq('prediccion-del-proximo-token')
  end

  it 'repeats a slug only in another language or another resource' do
    create(:resource_concept, resource:, slug: 'token')

    expect(build(:resource_concept, resource:, slug: 'token')).not_to be_valid
    expect(build(:resource_concept, resource:, slug: 'token', lang: 'en')).to be_valid
    expect(build(:resource_concept, resource: create(:resource), slug: 'token')).to be_valid
  end

  it 'rejects related slugs that are not concepts of the same resource and language' do
    create(:resource_concept, resource:, slug: 'token')
    create(:resource_concept, resource:, slug: 'agente', lang: 'en')

    concept = build(:resource_concept, resource:, related_slugs: 'token, agente, nada')

    expect(concept).not_to be_valid
    expect(concept.errors[:related_slugs].join).to include('agente', 'nada')
    expect(concept.errors[:related_slugs].join).not_to include('token')
  end

  # [[slug]] and [[slug|texto]] in the text of a card link to another card;
  # a slug that is not one fails here, not on the site (#226).
  describe 'links marked in the text' do
    before do
      create(:resource_concept, resource:, slug: 'arnes')
      create(:resource_concept, resource:, slug: 'agente', lang: 'en')
    end

    it 'takes links to cards of the same resource and language, with or without their own text' do
      concept = build(:resource_concept, resource:, definition: 'Un [[arnes]] y varios [[arnes|arneses]].',
                                         practice: 'Se enlaza a sí mismo: [[token]].', slug: 'token')

      expect(concept).to be_valid
    end

    it 'names the field and the slugs that are not cards of this resource and language' do
      concept = build(:resource_concept, resource:, definition: 'Ver [[agente]] y [[ nada | otra cosa ]].',
                                         analogy: 'Como un [[arnes]].', correction: 'Ver [[tampoco]].')

      expect(concept).not_to be_valid
      expect(concept.errors[:definition].join).to include('agente', 'nada')
      expect(concept.errors[:analogy]).to be_empty
      expect(concept.errors[:correction].join).to include('tampoco')
    end

    it 'lists the slugs a card links to' do
      concept = described_class.new(definition: '[[a]] y [[b|be]]', practice: '[[a]]')

      expect(concept.linked_slugs).to eq(%w[a b])
    end
  end

  it 'reads related slugs as a list' do
    expect(described_class.new(related_slugs: ' token,contexto ,, ').related).to eq(%w[token contexto])
  end

  it 'goes away with its resource, in reading order while it lives' do
    create(:resource_concept, resource:, position: 2, slug: 'b')
    create(:resource_concept, resource:, position: 1, slug: 'a')

    expect(resource.concepts.map(&:slug)).to eq(%w[a b])
    expect { resource.destroy }.to change(described_class, :count).by(-2)
  end
end
