# frozen_string_literal: true

require 'rails_helper'

describe Trainer do
  it 'should require a name' do
    t = FactoryBot.build(:trainer)

    t.name = ''

    expect(t.valid?).to be false
  end

  it 'should let me set a bio' do
    t = FactoryBot.build(:trainer)

    t.bio = 'Mini bio'

    expect(t.valid?).to be true
  end

  it 'should let me set a gravatar e-mail' do
    t = FactoryBot.build(:trainer)

    t.gravatar_email = 'malaimo@gmail.com'

    expect(t.valid?).to be true
  end

  it 'should let me set a twittwr username' do
    t = FactoryBot.build(:trainer)

    t.twitter_username = 'martinalaimo'

    expect(t.valid?).to be true
  end

  it 'should let me set a linkein url' do
    t = FactoryBot.build(:trainer)

    t.linkedin_url = 'http://ar.linkedin.com/in/malaimo'

    expect(t.valid?).to be true
  end

  it 'should let me indicate if the trainer is a kleerer' do
    t = FactoryBot.build(:trainer)

    t.is_kleerer = true

    expect(t.valid?).to be true
  end

  it 'should calculate the gravatar for malaimo e-mail' do
    t = FactoryBot.build(:trainer)

    t.gravatar_email = 'malaimo@gmail.com'

    expect(t.gravatar_picture_url).to eq 'http://www.gravatar.com/avatar/e92b3ae0ce91e1baf19a7bc62ac03297'
  end

  it 'should calculate the gravatar for jgabardini e-mail' do
    t = FactoryBot.build(:trainer)

    t.gravatar_email = 'jgabardini@computer.org'

    expect(t.gravatar_picture_url).to eq 'http://www.gravatar.com/avatar/72c191f31437b3250822b38d5f57705b'
  end

  it 'should handle a nil gravatar e-mail' do
    t = FactoryBot.build(:trainer)

    t.gravatar_email = nil

    expect(t.gravatar_picture_url).to eq 'http://www.gravatar.com/avatar/asljasld'
  end

  it 'should have a crm tag' do
    t = FactoryBot.build(:trainer)

    t.tag_name = 'TR-CP (Carlos Peix)'

    expect(t.valid?).to be true
  end
end
