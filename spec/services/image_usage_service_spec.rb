require 'rails_helper'

RSpec.describe ImageUsageService do
  let(:image_url) { 'http://example.com/image.jpg' }

  describe '.find_usage' do
    context 'when image is used in EventType' do
      it 'finds direct usage in URL fields' do
        event_type = create(:event_type, brochure: image_url)

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          { id: event_type.id, field: :brochure, type: 'direct' }
        )
      end

      it 'finds embedded usage in text fields' do
        event_type = create(:event_type, description: "Some text with #{image_url} embedded")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          { id: event_type.id, field: :description, type: 'embedded' }
        )
      end

      it 'finds multiple usages across different fields and types' do
        event_type1 = create(:event_type, cover: image_url)
        event_type2 = create(:event_type, program: "Program with #{image_url}")

        result = ImageUsageService.find_usage(image_url)

        expect(result[:event_type]).to include(
          { id: event_type1.id, field: :cover, type: 'direct' },
          { id: event_type2.id, field: :program, type: 'embedded' }
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

  describe '.search_event_type' do
    it 'searches in all specified URL fields' do
      event_type1 = create(:event_type, brochure: image_url)
      event_type2 = create(:event_type, cover: image_url)
      event_type3 = create(:event_type, kleer_cert_seal_image: image_url)

      result = ImageUsageService.send(:search_event_type, image_url)

      expect(result).to include(
        { id: event_type1.id, field: :brochure, type: 'direct' },
        { id: event_type2.id, field: :cover, type: 'direct' },
        { id: event_type3.id, field: :kleer_cert_seal_image, type: 'direct' }
      )
    end

    it 'searches in all specified text fields' do
      event_type1 = create(:event_type, description: "Description with #{image_url}")
      event_type3 = create(:event_type, program: "Program with #{image_url}")

      result = ImageUsageService.send(:search_event_type, image_url)

      expect(result).to include(
        { id: event_type1.id, field: :description, type: 'embedded' },
        { id: event_type3.id, field: :program, type: 'embedded' }
      )
    end
  end
end
