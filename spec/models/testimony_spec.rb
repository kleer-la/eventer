# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Testimony, type: :model do
  describe 'factory' do
    it 'creates a valid testimony' do
      testimony = build(:testimony)
      expect(testimony).to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to service' do
      testimony = build(:testimony)
      expect(testimony.service).to be_present
      expect(testimony).to respond_to(:service)
    end

    it 'has rich text testimony' do
      testimony = build(:testimony)
      expect(testimony).to respond_to(:testimony)
      expect(testimony.testimony).to be_a(ActionText::RichText)
    end

    it 'creates testimony with associated service' do
      service = create(:service)
      testimony = create(:testimony, service: service)

      expect(testimony.service).to eq(service)
      expect(service.testimonies).to include(testimony)
    end
  end

  describe 'attributes' do
    let(:testimony) { build(:testimony) }

    it 'has required attributes' do
      expect(testimony).to respond_to(:first_name)
      expect(testimony).to respond_to(:last_name)
      expect(testimony).to respond_to(:profile_url)
      expect(testimony).to respond_to(:photo_url)
      expect(testimony).to respond_to(:stared)
      expect(testimony).to respond_to(:testimony)
    end

    it 'stores boolean stared attribute correctly' do
      testimony.stared = true
      expect(testimony.stared).to be true

      testimony.stared = false
      expect(testimony.stared).to be false
    end
  end

  describe 'ActionText integration' do
    it 'stores rich text content' do
      testimony = create(:testimony, :with_rich_content)

      expect(testimony.testimony.body.to_s).to include('<strong>absolutely fantastic</strong>')
      expect(testimony.testimony.to_plain_text).to include('absolutely fantastic')
    end

    it 'handles plain text content' do
      plain_text = 'This is a simple testimony without formatting.'
      testimony = create(:testimony, testimony: plain_text)

      expect(testimony.testimony.to_plain_text.strip).to eq(plain_text)
    end
  end

  describe 'ImageReference concern' do
    it 'includes ImageReference concern' do
      expect(Testimony.included_modules).to include(ImageReference)
    end

    it 'references images in photo_url field' do
      testimony = create(:testimony, photo_url: 'https://example.com/photo.jpg')

      expect(testimony.photo_url).to eq('https://example.com/photo.jpg')
    end
  end

  describe 'Ransack functionality' do
    describe '.ransackable_attributes' do
      it 'returns expected searchable attributes' do
        expected_attributes = %w[created_at first_name id id_value last_name photo_url
                                 profile_url service_id stared updated_at]

        expect(Testimony.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'returns expected searchable associations' do
        expected_associations = %w[rich_text_testimony service]

        expect(Testimony.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'scopes and queries' do
    let!(:starred_testimony) { create(:testimony, :starred) }
    let!(:regular_testimony) { create(:testimony, stared: false) }

    it 'can filter by starred status' do
      starred_testimonies = Testimony.where(stared: true)
      regular_testimonies = Testimony.where(stared: false)

      expect(starred_testimonies).to include(starred_testimony)
      expect(starred_testimonies).not_to include(regular_testimony)
      expect(regular_testimonies).to include(regular_testimony)
      expect(regular_testimonies).not_to include(starred_testimony)
    end

    it 'can search by name fields' do
      john_testimony = create(:testimony, first_name: 'John', last_name: 'Smith')
      jane_testimony = create(:testimony, first_name: 'Jane', last_name: 'Doe')

      johns = Testimony.where('first_name LIKE ?', '%John%')
      janes = Testimony.where('first_name LIKE ?', '%Jane%')

      expect(johns).to include(john_testimony)
      expect(johns).not_to include(jane_testimony)
      expect(janes).to include(jane_testimony)
      expect(janes).not_to include(john_testimony)
    end
  end

  describe 'data integrity' do
    it 'maintains foreign key relationship with service' do
      service = create(:service)
      create(:testimony, service: service)

      expect { service.destroy! }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it 'handles optional URLs gracefully' do
      testimony = create(:testimony, :without_urls)

      expect(testimony.profile_url).to be_nil
      expect(testimony.photo_url).to be_nil
      expect(testimony).to be_valid
    end
  end
end
