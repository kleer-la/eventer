# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceArea, type: :model do
  it 'trims slug before saving on create' do
    service_area = FactoryBot.build(:service_area, slug: '  test-slug  ')
    service_area.save
    expect(service_area.slug).to eq('test-slug')
  end
  it 'trims slug before saving on modify' do
    service_area = FactoryBot.create(:service_area)
    service_area.slug = '  test-slug  '
    service_area.save
    expect(service_area.slug).to eq('test-slug')
  end

  # The area carries the same offering blocks a service does, parsed the same
  # way, so its page can sell it without a service underneath.
  describe 'offering content' do
    it 'parses outcomes, program and faq like a service' do
      area = ServiceArea.new
      area.outcomes = ActionText::Content.new('<ul><li>uno</li><li>dos</li></ul>')
      area.program = ActionText::Content.new('<ol><li>Módulo<ul><li>Detalle <em>uno</em></li></ul></li></ol>')
      area.faq = ActionText::Content.new('<ol><li>¿Cuándo?<ul><li>Pronto</li></ul></li></ol>')

      expect(area.outcomes_list).to eq(%w[uno dos])
      expect(area.program_list).to eq([['Módulo', 'Detalle <em>uno</em>']])
      expect(area.faq_list).to eq([['¿Cuándo?', 'Pronto']])
    end

    it 'has no outcomes, program or faq until given' do
      area = FactoryBot.create(:service_area)

      expect(area.outcomes_list).to be_nil
      expect(area.program_list).to eq([])
      expect(area.faq_list).to eq([])
    end

    it 'stores pricing and brochure' do
      area = FactoryBot.create(:service_area, pricing: 'Desde USD 1.000', brochure: 'https://example.com/b.pdf')

      expect(area.reload.pricing).to eq('Desde USD 1.000')
      expect(area.brochure).to eq('https://example.com/b.pdf')
    end

    it 'recommends content like a service does' do
      area = FactoryBot.create(:service_area)
      article = FactoryBot.create(:article)
      FactoryBot.create(:recommended_content, source: area, target: article, relevance_order: 5)

      recommended = area.recommended
      expect(recommended.size).to eq(1)
      expect(recommended.first['type']).to eq('article')
      expect(recommended.first['id']).to eq(article.id)
    end
  end

  describe 'trainers association' do
    it 'can be associated with trainers' do
      service_area = FactoryBot.create(:service_area)
      trainer = FactoryBot.create(:trainer)

      service_area.trainers << trainer

      expect(service_area.trainers).to include(trainer)
    end
  end

  # The old URL of a renamed area or service keeps resolving, even when the
  # history had no row for it (kleer-la/eventer#208).
  describe 'renaming the slug' do
    it 'keeps finding it by the slug it left' do
      record = FactoryBot.create(:service_area, slug: 'agile-product-management')

      record.update!(slug: 'producto-digital')

      expect(ServiceArea.friendly.find('agile-product-management')).to eq record
      expect(ServiceArea.friendly.find('producto-digital')).to eq record
    end

    it 'remembers the old slug even when the history did not have it' do
      record = FactoryBot.create(:service_area, slug: 'agile-product-management')
      record.slugs.delete_all

      record.update!(slug: 'producto-digital')

      expect(ServiceArea.friendly.find('agile-product-management')).to eq record
    end
  end
end
