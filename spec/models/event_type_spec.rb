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

  context 'Testimonies' do
    it 'no event no testimony' do
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'no participant no testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant wo/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      p = FactoryBot.create(:participant, event: ev)
      expect(@event_type.testimonies.count).to eq 0
    end
    it 'participant w/ testimony' do
      ev = FactoryBot.create(:event, event_type: @event_type)
      p = FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 1
    end
    it "shouldn't include participant other event type" do
      et = FactoryBot.create(:event_type)
      ev = FactoryBot.create(:event, event_type: et)
      p = FactoryBot.create(:participant, event: ev, testimony: 'Hello, Joe')
      expect(@event_type.testimonies.count).to eq 0
    end
  end
end
