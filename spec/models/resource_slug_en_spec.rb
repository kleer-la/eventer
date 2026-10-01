# frozen_string_literal: true

require 'rails_helper'

# A resource may have an English slug of its own (#227): optional, unique
# across every slug of every resource, remembered when it changes so the site
# can answer the old URL with a 301, and the same as the Spanish one if wanted.
RSpec.describe Resource do
  let!(:prompt) { create(:resource, title_es: 'Prompt para comunicarte', slug: 'prompt-comunicarte') }
  let!(:kartas) { create(:resource, title_es: 'Kartas', slug: 'kartas', slug_en: 'agile-kards') }

  describe 'slug_en' do
    it 'is optional, and blank means none' do
      prompt.update!(slug_en: '  ')

      expect(prompt.reload.slug_en).to be_nil
    end

    it 'can be the same as its own Spanish slug' do
      expect(prompt.update(slug_en: 'prompt-comunicarte')).to be true
    end

    it 'cannot take the Spanish or English slug of another resource, and names it' do
      prompt.slug_en = 'kartas'
      expect(prompt).not_to be_valid
      expect(prompt.errors[:slug_en].join).to include('kartas', 'Kartas')

      prompt.slug_en = 'agile-kards'
      expect(prompt).not_to be_valid
    end

    it 'keeps the other way round too: a Spanish slug cannot be another English one' do
      prompt.slug = 'agile-kards'

      expect(prompt).not_to be_valid
      expect(prompt.errors[:slug].join).to include('agile-kards', 'Kartas')
    end

    it 'cannot take a slug another resource had' do
      kartas.update!(slug_en: 'evolution-kards')

      prompt.slug_en = 'agile-kards'
      expect(prompt).not_to be_valid
    end

    it 'takes only lowercase letters, digits and dashes' do
      prompt.slug_en = 'Prompt Comunicar'

      expect(prompt).not_to be_valid
      expect(prompt.errors[:slug_en]).to be_present
    end
  end

  describe '.find_by_any_slug' do
    it 'finds by the Spanish slug, the English one, or an old one of either' do
      kartas.update!(slug_en: 'evolution-kards')
      kartas.update!(slug: 'kartas-nuevas')

      %w[kartas-nuevas evolution-kards agile-kards kartas].each do |slug|
        expect(described_class.find_by_any_slug(slug)).to eq(kartas), slug
      end
    end

    it 'raises not found for a slug nobody has' do
      expect { described_class.find_by_any_slug('nada') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  it 'recommends itself under the slug of the language, so the card does not go through a 301' do
    expect(kartas.as_recommendation(lang: 'en')['slug']).to eq('agile-kards')
    expect(kartas.as_recommendation(lang: 'es')['slug']).to eq('kartas')
  end

  it 'answers the slug of each language' do
    expect(kartas.slug_for('en')).to eq('agile-kards')
    expect(kartas.slug_for('es')).to eq('kartas')
    expect(prompt.slug_for('en')).to eq('prompt-comunicarte')
  end
end
