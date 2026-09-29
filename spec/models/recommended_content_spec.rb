# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecommendedContent, type: :model do
  describe '.ransackable_attributes' do
    it 'returns the correct list of ransackable attributes' do
      expect(RecommendedContent.ransackable_attributes).to match_array(
        %w[created_at id id_value relevance_order source_id source_type target_id target_type updated_at]
      )
    end
  end

  describe '.ransackable_associations' do
    it 'returns the correct list of ransackable associations' do
      expect(RecommendedContent.ransackable_associations).to match_array(%w[source target])
    end
  end

  describe 'functionality' do
    let(:event_type1) { create(:event_type) }
    let(:event_type2) { create(:event_type) }

    it 'creates a valid recommended content' do
      recommended_content = RecommendedContent.new(
        source: event_type1,
        target: event_type2,
        relevance_order: 1
      )
      expect(recommended_content).to be_valid
    end

    it 'refuses a page with no URL of its own' do
      overlay = create(:page, name: 'Contacto', lang: :es, template: 'overlay')

      link = RecommendedContent.new(source: event_type1, target: overlay, relevance_order: 1)

      expect(link).to be_invalid
      expect(link.errors[:target].join).to include('overlay page')
    end

    it 'accepts a flagship page, which is routed at /:lang/:slug' do
      flagship = create(:page, name: 'Membresía IA', lang: :es, template: 'flagship')

      expect(RecommendedContent.new(source: event_type1, target: flagship, relevance_order: 1)).to be_valid
    end

    it 'does not allow relevance_order to be less than 1' do
      recommended_content = RecommendedContent.new(
        source: event_type1,
        target: event_type2,
        relevance_order: 0
      )
      expect(recommended_content).to be_invalid
      expect(recommended_content.errors[:relevance_order]).to include('debe ser mayor o igual a 1')
    end

    # The site renders `recommended` as cards, so a target it would not serve
    # (unpublished, or answered with a 301 elsewhere) must not become a card.
    # The link itself stays: the admin still lists it (kleer-la/eventer#213).
    describe 'what the source serves as recommended' do
      let(:source) { create(:article, published: true) }

      def recommend(target)
        RecommendedContent.create!(source:, target:, relevance_order: 1)
      end

      it 'skips an unpublished article' do
        recommend(create(:article, published: false))

        expect(source.recommended).to be_empty
      end

      it 'skips a published article that redirects elsewhere' do
        recommend(create(:article, published: true, redirect_url: '/es/blog/otro'))

        expect(source.recommended).to be_empty
      end

      it 'skips an unpublished resource and an unpublished service' do
        recommend(create(:resource, published: false))
        recommend(create(:service, published: false))

        expect(source.recommended).to be_empty
      end

      it 'skips a deleted event type' do
        recommend(create(:event_type, deleted: true))

        expect(source.recommended).to be_empty
      end

      it 'serves what is published' do
        target = create(:article, published: true)
        recommend(target)

        expect(source.recommended.map { |card| card['id'] }).to eq([target.id])
      end

      it 'still lists everything for the admin' do
        recommend(create(:article, published: false))

        expect(source.recommended(include_unpublished: true).size).to eq(1)
      end
    end

    it 'allows different types of sources and targets' do
      article = create(:article) # Assuming you have an Article model
      recommended_content = RecommendedContent.new(
        source: event_type1,
        target: article,
        relevance_order: 1
      )
      expect(recommended_content).to be_valid
    end
  end
end
