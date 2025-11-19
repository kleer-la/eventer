# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe Ability do
  describe 'administrator' do
    let(:user) { create(:administrator) }
    let(:ability) { Ability.new(user) }

    it 'can manage all resources' do
      expect(ability).to be_able_to(:manage, Event)
      expect(ability).to be_able_to(:manage, EventType)
      expect(ability).to be_able_to(:manage, Participant)
      expect(ability).to be_able_to(:manage, User)
    end

    it 'can destroy resources' do
      expect(ability).to be_able_to(:destroy, Event)
      expect(ability).to be_able_to(:destroy, EventType)
      expect(ability).to be_able_to(:destroy, Participant)
    end
  end

  describe 'comercial user' do
    let(:user) { create(:comercial) }
    let(:ability) { Ability.new(user) }

    it 'can read all resources' do
      expect(ability).to be_able_to(:read, Event)
      expect(ability).to be_able_to(:read, EventType)
      expect(ability).to be_able_to(:read, Participant)
    end

    it 'can create resources' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Participant)
    end

    it 'can update resources' do
      expect(ability).to be_able_to(:update, Event)
      expect(ability).to be_able_to(:update, EventType)
      expect(ability).to be_able_to(:update, Participant)
    end

    it 'cannot destroy resources' do
      expect(ability).not_to be_able_to(:destroy, Event)
      expect(ability).not_to be_able_to(:destroy, EventType)
      expect(ability).not_to be_able_to(:destroy, Participant)
    end
  end

  describe 'marketing user' do
    let(:user) { create(:marketing_user) }
    let(:ability) { Ability.new(user) }

    it 'can read all resources' do
      expect(ability).to be_able_to(:read, Event)
      expect(ability).to be_able_to(:read, EventType)
      expect(ability).to be_able_to(:read, Article)
    end

    it 'can create resources' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Article)
    end

    it 'can update resources' do
      expect(ability).to be_able_to(:update, Event)
      expect(ability).to be_able_to(:update, EventType)
      expect(ability).to be_able_to(:update, Article)
    end

    it 'cannot destroy resources' do
      expect(ability).not_to be_able_to(:destroy, Event)
      expect(ability).not_to be_able_to(:destroy, EventType)
      expect(ability).not_to be_able_to(:destroy, Article)
    end
  end

  describe 'content user' do
    let(:user) { create(:content_user) }
    let(:ability) { Ability.new(user) }

    it 'can read all resources' do
      expect(ability).to be_able_to(:read, Event)
      expect(ability).to be_able_to(:read, EventType)
      expect(ability).to be_able_to(:read, Article)
    end

    it 'can create resources' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Article)
    end

    it 'can update resources' do
      expect(ability).to be_able_to(:update, Event)
      expect(ability).to be_able_to(:update, EventType)
      expect(ability).to be_able_to(:update, Article)
    end

    it 'cannot destroy resources' do
      expect(ability).not_to be_able_to(:destroy, Event)
      expect(ability).not_to be_able_to(:destroy, EventType)
      expect(ability).not_to be_able_to(:destroy, Article)
    end
  end

  describe 'user without roles' do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }

    it 'can only read dashboard' do
      expect(ability).to be_able_to(:read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin')
    end

    it 'cannot manage resources' do
      expect(ability).not_to be_able_to(:manage, Event)
      expect(ability).not_to be_able_to(:manage, EventType)
    end
  end
end
