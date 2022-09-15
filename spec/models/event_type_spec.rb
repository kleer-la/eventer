# frozen_string_literal: true

require 'rails_helper'

describe EventType do
  before(:each) do
    @event_type = FactoryBot.create(:event_type)
  end

  it 'HABTM trainers' do
    expect(@event_type.trainers[0].name).to eq 'Juan Alberto'
  end
  it 'HABTM categories' do
    expect(@event_type.categories).to eq []
  end

  it 'should be valid' do
    expect(@event_type.valid?).to be true
  end

  it 'should require its name' do
    @event_type.name = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its description' do
    @event_type.description = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require an elevator pitch' do
    @event_type.elevator_pitch = ''

    expect(@event_type.valid?).to be false
  end

  it 'elevator pitch invalid if +160 chars' do
    @event_type.elevator_pitch = 'x' * 161

    expect(@event_type.valid?).to be false
  end

  it 'should require its recipients' do
    @event_type.recipients = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its program' do
    @event_type.program = ''

    expect(@event_type.valid?).to be false
  end

  it 'should require its duration' do
    @event_type.duration = ''

    expect(@event_type.valid?).to be true
  end

  it 'should have a shot_name version returning 30 characters if name is longer' do
    @event_type.name = 'qoweiuq owei owqieu qoiweuqo iweu qwoeu qouwie qowieuq woiequ woei uqowie'
    expect(@event_type.short_name).to eq 'qoweiuq owei owqieu qoiweuqo i...'
  end

  it 'should have a shot_name version returning all characters if name is shorter than 30 letters' do
    @event_type.name = 'hola che!'
    expect(@event_type.short_name).to eq 'hola che!'
  end

  it 'should have a crm tag' do
    @event_type.tag_name = 'TR-CP (Carlos Peix)'
    expect(@event_type.valid?).to be true
  end

  it 'could not have a cover' do
    @event_type.cover = nil
    expect(@event_type.valid?).to be true
  end
  it 'could have a cover' do
    @event_type.cover = 'rambandanga'
    expect(@event_type.valid?).to be true
  end

  context 'Testimonies' do
    it 'no event no testimony' do
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant wo/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant w/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 1
    end
    it 'participant w/2 testimones one selected' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      FactoryBot.create(:participant, event: ev, testimony: 'Yeah', selected: true)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      testimonies = @event_type.testimonies
      expect(testimonies.count).to eq 3
      expect(testimonies[0].testimony).to eq 'Yeah'
    end
    it "shouldn't include participant other event type" do
      et = FactoryBot.create(:event_type)
      ev = FactoryBot.create(:event, event_type: et)
      FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 0
    end
  end
  context 'Slug & Canonical' do
    it 'allow stand alone event types' do
      et = FactoryBot.create(:event_type, id: 45, name: 'Joy Division (JD)')
      expect(et.slug).to eq '45-joy-division-jd'
    end
    it 'allow stand alone event types' do
      et = FactoryBot.create(:event_type)
      expect(et.canonical).to be_nil
      expect(et.clons).to eq []
    end
    it 'one canonical / one clon' do
      et1 = FactoryBot.create(:event_type, name: 'Original')
      et2 = FactoryBot.create(:event_type, name: 'Academia', canonical: et1)
      expect(et1.canonical).to be_nil
      expect(et1.clons.count).to eq 1
      expect(et1.clons[0].id).to eq et2.id

      expect(et2.canonical.id).to eq et1.id
      expect(et2.clons).to eq []
    end
    it 'stand alone event types canonical_slug are themself' do
      et = FactoryBot.create(:event_type, id: 504, name: 'Un Curso')
      expect(et.slug).to eq '504-un-curso'
      expect(et.canonical_slug).to eq '504-un-curso'
    end
    it 'stand alone event types canonical_slug are themself' do
      et1 = FactoryBot.create(:event_type, id: 23, name: 'Original')
      et2 = FactoryBot.create(:event_type, id: 42, name: 'Academia', canonical: et1)
      expect(et2.slug).to eq '42-academia'
      expect(et2.canonical_slug).to eq '23-original'
    end
  end
  context 'Deleted & noindex' do
    it 'New event type is no deleted and indexed' do
      et = FactoryBot.create(:event_type)
      expect(et.deleted).to be false
      expect(et.noindex).to be false
    end
  end
  context 'v2022 website fields' do
    it 'New event type has new fields: side_image, brochure, new_version' do
      et = FactoryBot.create(:event_type, side_image: 'alpha', brochure: 'beta')
      expect(et.new_version).to be false
      expect(et.side_image).to eq 'alpha'
      expect(et.brochure).to eq 'beta'
    end
  end
end
