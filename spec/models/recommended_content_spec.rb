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

    it 'does not allow relevance_order to be less than 1' do
      recommended_content = RecommendedContent.new(
        source: event_type1,
        target: event_type2,
        relevance_order: 0
      )
      expect(recommended_content).to be_invalid
      expect(recommended_content.errors[:relevance_order]).to include('debe ser mayor o igual a 1')
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
