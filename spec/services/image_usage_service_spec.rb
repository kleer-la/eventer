require 'rails_helper'

RSpec.describe ImageUsageService do
  let(:image_url) { 'http://example.com/image.jpg' }

  before(:all) do
    Rails.application.eager_load!
  end

  before do
    # Ensure models are loaded and registered
    Rails.application.eager_load!
  end

  describe '.find_usage' do
    context 'when image is used in EventType' do
      it 'finds direct usage in URL fields' do
        event_type = create(:event_type, brochure: image_url)

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          hash_including(id: event_type.id, field: :brochure, type: 'direct')
        )
      end

      it 'finds embedded usage in text fields' do
        event_type = create(:event_type, description: "Some text with #{image_url} embedded")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          hash_including(id: event_type.id, field: :description, type: 'embedded')
        )
      end

      it 'finds multiple usages across different fields and types' do
        event_type1 = create(:event_type, cover: image_url)
        event_type2 = create(:event_type, program: "Program with #{image_url}")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          hash_including(id: event_type1.id, field: :cover, type: 'direct'),
          hash_including(id: event_type2.id, field: :program, type: 'embedded')
        )
      end
    end

    context 'when image is used in Article' do
      it 'finds direct usage in URL fields' do
        article = create(:article, cover: image_url)

        result = ImageUsageService.find_usage(image_url)

        expect(result[:article]).to include(
          hash_including(id: article.id, field: :cover, type: 'direct')
        )
      end

      it 'finds embedded usage in text fields' do
        article = create(:article, body: "Article body with #{image_url} embedded")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:article]).to include(
          hash_including(id: article.id, field: :body, type: 'embedded')
        )
      end
    end

    context 'when image is used in multiple models' do
      it 'finds usage across different models' do
        event_type = create(:event_type, cover: image_url)
        article = create(:article, description: "Description with #{image_url}")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          hash_including(id: event_type.id, field: :cover, type: 'direct')
        )
        expect(result[:article]).to include(
          hash_including(id: article.id, field: :description, type: 'embedded')
        )
      end
    end

    context 'when image is not used' do
      it 'returns an empty hash' do
        result = ImageUsageService.find_usage(image_url)
        expect(result).to be_empty
      end
    end
  end

  describe '.register_model' do
    let(:test_model) do
      Class.new(ApplicationRecord) do
        self.table_name = 'articles'
        include ImageReference
      end
    end

    let(:original_models) { described_class.registered_models.dup }

    before do
      # Save original state
      @original_models = described_class.registered_models.dup
      # Clear for isolated testing
      described_class.instance_variable_set(:@registered_models, Set.new)
    end

    after do
      # Restore original state, filtering out any anonymous test classes
      clean_models = @original_models.select { |model| model.name.present? }
      described_class.instance_variable_set(:@registered_models, Set.new(clean_models))
    end

    it 'adds model to registered_models' do
      described_class.register_model(test_model)
      expect(described_class.registered_models).to include(test_model)
    end

    it 'prevents duplicate registration' do
      2.times { described_class.register_model(test_model) }
      expect(described_class.registered_models.count(test_model)).to eq(1)
    end
  end

  describe 'with ImageReference concern' do
    before(:all) do
      # Ensure all models are loaded and registered
      Rails.application.eager_load!
    end

    it 'finds references based on configured fields' do
      event_type = create(:event_type,
                          cover: image_url,
                          description: 'Some text',
                          side_image: 'other_image.jpg')

      result = described_class.find_usage(image_url)

      # Should find the cover reference
      expect(result[:event_type]).to include(
        hash_including(
          id: event_type.id,
          field: :cover,
          type: 'direct'
        )
      )

      # Should not include side_image since it has a different URL
      expect(result[:event_type]).not_to include(
        hash_including(
          field: :side_image
        )
      )
    end

    describe 'comprehensive model testing' do
      before do
        # Ensure ImageUsageService has all models registered for these tests
        Rails.application.eager_load!
      end
      it 'finds usage in News model' do
        create(:news, img: image_url, description: "Text with #{image_url}")

        result = described_class.find_usage(image_url)

        expect(result[:news]).to include(
          hash_including(field: :img, type: 'direct'),
          hash_including(field: :description, type: 'embedded')
        )
      end

      it 'finds usage in Coupon model' do
        create(:coupon, icon: image_url)

        result = described_class.find_usage(image_url)

        expect(result[:coupon]).to include(
          hash_including(field: :icon, type: 'direct')
        )
      end

      it 'finds usage in Assessment model' do
        create(:assessment, description: "Assessment with #{image_url}")

        result = described_class.find_usage(image_url)

        expect(result[:assessment]).to include(
          hash_including(field: :description, type: 'embedded')
        )
      end

      it 'finds usage in Question model' do
        create(:question, description: "Question with #{image_url}")

        result = described_class.find_usage(image_url)

        expect(result[:question]).to include(
          hash_including(field: :description, type: 'embedded')
        )
      end

      it 'finds usage in Answer model' do
        create(:answer, text: "Answer with #{image_url}")

        result = described_class.find_usage(image_url)

        expect(result[:answer]).to include(
          hash_including(field: :text, type: 'embedded')
        )
      end

      it 'finds usage in QuestionGroup model' do
        create(:question_group, description: "Group with #{image_url}")

        result = described_class.find_usage(image_url)

        expect(result[:question_group]).to include(
          hash_including(field: :description, type: 'embedded')
        )
      end

      it 'finds usage across all registered models simultaneously' do
        # Create records with the same image URL in different models
        create(:article, cover: image_url)
        create(:news, video: image_url)
        create(:coupon, icon: image_url)
        create(:assessment, description: "Assessment with #{image_url}")

        result = described_class.find_usage(image_url)

        # Should find usage in all models
        expect(result.keys).to include(:article, :news, :coupon, :assessment)
        expect(result[:article]).to include(hash_including(field: :cover, type: 'direct'))
        expect(result[:news]).to include(hash_including(field: :video, type: 'direct'))
        expect(result[:coupon]).to include(hash_including(field: :icon, type: 'direct'))
        expect(result[:assessment]).to include(hash_including(field: :description, type: 'embedded'))
      end
    end
  end
end
