require 'rails_helper'

RSpec.describe ImageUsageService do
  let(:image_url) { 'http://example.com/image.jpg' }

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
end
