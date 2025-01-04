# spec/models/concerns/image_reference_spec.rb
require 'rails_helper'

RSpec.describe ImageReference do
  let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/test.jpg' }

  # Create a test model class with minimal needs
  let(:test_model) do
    Class.new(ApplicationRecord) do
      self.table_name = 'articles' # Using articles table since it likely has a slug
      include ImageReference

      references_images_in :cover,
                           text_fields: [:description]
    end
  end

  describe '.references_images_in' do
    it 'sets image_url_fields' do
      expect(test_model.image_url_fields).to contain_exactly(:cover)
    end

    it 'sets image_text_fields' do
      expect(test_model.image_text_fields).to contain_exactly(:description)
    end

    it 'registers the model with ImageUsageService' do
      expect(ImageUsageService.registered_models).to include(test_model)
    end
  end

  describe '#image_references' do
    let(:instance) do
      test_model.new(
        cover: image_url,
        description: "Some text with #{image_url} embedded"
      )
    end

    it 'finds direct references in URL fields' do
      references = instance.image_references(image_url)
      expect(references).to include(
        hash_including(
          field: :cover,
          type: 'direct'
        )
      )
    end

    it 'finds embedded references in text fields' do
      references = instance.image_references(image_url)
      expect(references).to include(
        hash_including(
          field: :description,
          type: 'embedded'
        )
      )
    end

    context 'when model has slug' do
      before do
        allow(instance).to receive(:respond_to?).with(:slug, any_args).and_return(true)
        allow(instance).to receive(:slug).and_return('test-slug')
      end

      it 'includes slug if available' do
        references = instance.image_references(image_url)
        expect(references.first).to include(slug: 'test-slug')
      end
    end

    context 'when model does not have slug' do
      before do
        allow(instance).to receive(:respond_to?).with(:slug, any_args).and_return(false)
      end

      it 'handles missing slug gracefully' do
        references = instance.image_references(image_url)
        expect(references.first).to include(slug: nil)
      end
    end
  end
end
