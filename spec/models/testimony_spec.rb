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
    it 'belongs to testimonial polymorphically' do
      testimony = build(:testimony)
      expect(testimony).to respond_to(:testimonial)
      expect(testimony).to respond_to(:testimonial_type)
      expect(testimony).to respond_to(:testimonial_id)
    end

    it 'has rich text testimony' do
      testimony = build(:testimony)
      expect(testimony).to respond_to(:testimony)
      expect(testimony.testimony).to be_a(ActionText::RichText)
    end

    it 'creates testimony with associated service' do
      service = create(:service)
      testimony = create(:testimony, testimonial: service)

      expect(testimony.testimonial).to eq(service)
      expect(testimony.testimonial_type).to eq('Service')
      expect(service.testimonies).to include(testimony)
    end

    it 'creates testimony with associated event_type' do
      event_type = create(:event_type)
      testimony = create(:testimony, testimonial: event_type)

      expect(testimony.testimonial).to eq(event_type)
      expect(testimony.testimonial_type).to eq('EventType')
      expect(event_type.testimonies).to include(testimony)
    end

    it 'supports backward compatibility with service association' do
      service = create(:service)
      testimony = create(:testimony, service: service)

      expect(testimony.service).to eq(service)
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
                                 profile_url service_id stared testimonial_id testimonial_type updated_at]

        expect(Testimony.ransackable_attributes).to match_array(expected_attributes)
      end
    end

    describe '.ransackable_associations' do
      it 'returns expected searchable associations' do
        expected_associations = %w[rich_text_testimony service testimonial]

        expect(Testimony.ransackable_associations).to match_array(expected_associations)
      end
    end
  end

  describe 'scopes and queries' do
    let!(:starred_testimony) { create(:testimony, :starred) }
    let!(:regular_testimony) { create(:testimony, stared: false) }

    it 'can filter by starred status using scope' do
      expect(Testimony.starred).to include(starred_testimony)
      expect(Testimony.starred).not_to include(regular_testimony)
    end

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

    it 'can filter testimonies for specific event_type' do
      event_type = create(:event_type)
      testimony1 = create(:testimony, testimonial: event_type)
      testimony2 = create(:testimony, testimonial: create(:event_type))

      expect(Testimony.for_event_type(event_type.id)).to include(testimony1)
      expect(Testimony.for_event_type(event_type.id)).not_to include(testimony2)
    end

    it 'can filter testimonies for specific service' do
      service = create(:service)
      testimony1 = create(:testimony, testimonial: service)
      testimony2 = create(:testimony, testimonial: create(:service))

      expect(Testimony.for_service(service.id)).to include(testimony1)
      expect(Testimony.for_service(service.id)).not_to include(testimony2)
    end
  end

  describe 'data integrity' do
    it 'destroys testimonies when event_type is destroyed' do
      event_type = create(:event_type)
      testimony = create(:testimony, testimonial: event_type)

      expect { event_type.destroy! }.to change { Testimony.count }.by(-1)
    end

    it 'destroys testimonies when service is destroyed' do
      service = create(:service)
      testimony = create(:testimony, testimonial: service)

      expect { service.destroy! }.to change { Testimony.count }.by(-1)
    end

    it 'handles optional URLs gracefully' do
      testimony = create(:testimony, :without_urls)

      expect(testimony.profile_url).to be_nil
      expect(testimony.photo_url).to be_nil
      expect(testimony).to be_valid
    end
  end

  describe 'validations' do
    it 'requires first_name' do
      testimony = build(:testimony, first_name: nil)
      expect(testimony).not_to be_valid
      expect(testimony.errors[:first_name]).to be_present
    end

    it 'requires last_name' do
      testimony = build(:testimony, last_name: nil)
      expect(testimony).not_to be_valid
      expect(testimony.errors[:last_name]).to be_present
    end

    it 'requires testimonial association' do
      testimony = build(:testimony, testimonial: nil)
      expect(testimony).not_to be_valid
      expect(testimony.errors[:testimonial]).to be_present
    end
  end
end
