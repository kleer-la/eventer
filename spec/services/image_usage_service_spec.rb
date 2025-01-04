require 'rails_helper'

RSpec.describe ImageUsageService do
  let(:image_url) { 'http://example.com/image.jpg' }

  before(:all) do
    Rails.application.eager_load!
  end

  before do
    # Clear registered models before each test
    described_class.instance_variable_set(:@registered_models, Set.new)

    # Register models with ImageReference
    [Article, EventType].each do |model|
      model.include ImageReference unless model.included_modules.include?(ImageReference)
    end
    Article.references_images_in :cover, text_fields: %i[body description]
    EventType.references_images_in :brochure, :cover, :kleer_cert_seal_image, :side_image,
                                   text_fields: %i[description program recipients faq]
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

    before do
      described_class.instance_variable_set(:@registered_models, Set.new)
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
    before do
      # Clear any existing registrations
      described_class.instance_variable_set(:@registered_models, Set.new)

      # Include and configure ImageReference in test models
      Article.include ImageReference
      Article.references_images_in :cover, text_fields: %i[body description]

      EventType.include ImageReference
      EventType.references_images_in :brochure, :cover, :kleer_cert_seal_image, :side_image,
                                     text_fields: %i[description program recipients faq]
    end

    it 'automatically registers models using ImageReference' do
      expect(described_class.registered_models).to include(Article, EventType)
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
  end
end
