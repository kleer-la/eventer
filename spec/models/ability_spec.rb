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
      expect(ability).to be_able_to(:manage, Article)
    end

    it 'can destroy resources' do
      expect(ability).to be_able_to(:destroy, Event)
      expect(ability).to be_able_to(:destroy, EventType)
      expect(ability).to be_able_to(:destroy, Article)
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

    it 'can create all resources' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Article)
    end

    it 'can update all resources' do
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

  describe 'comercial user' do
    let(:user) { create(:comercial) }
    let(:ability) { Ability.new(user) }

    it 'can read all resources' do
      expect(ability).to be_able_to(:read, Event)
      expect(ability).to be_able_to(:read, EventType)
      expect(ability).to be_able_to(:read, Article)
    end

    it 'cannot create resources' do
      expect(ability).not_to be_able_to(:create, Event)
      expect(ability).not_to be_able_to(:create, EventType)
      expect(ability).not_to be_able_to(:create, Article)
    end

    it 'cannot update resources' do
      expect(ability).not_to be_able_to(:update, Event)
      expect(ability).not_to be_able_to(:update, EventType)
      expect(ability).not_to be_able_to(:update, Article)
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

    it 'can create content models' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Article)
      expect(ability).to be_able_to(:create, Resource)
      expect(ability).to be_able_to(:create, Testimony)
    end

    it 'can update content models' do
      expect(ability).to be_able_to(:update, Event)
      expect(ability).to be_able_to(:update, EventType)
      expect(ability).to be_able_to(:update, Article)
      expect(ability).to be_able_to(:update, Resource)
    end

    it 'cannot set publishing fields' do
      expect(ability).not_to be_able_to(:set_include_in_catalog, EventType)
      expect(ability).not_to be_able_to(:set_published, Article)
      expect(ability).not_to be_able_to(:set_published, Resource)
    end

    it 'cannot destroy resources' do
      expect(ability).not_to be_able_to(:destroy, Event)
      expect(ability).not_to be_able_to(:destroy, EventType)
      expect(ability).not_to be_able_to(:destroy, Article)
    end
  end

  describe 'publisher user' do
    let(:user) { create(:publisher_user) }
    let(:ability) { Ability.new(user) }

    it 'can read all resources' do
      expect(ability).to be_able_to(:read, Event)
      expect(ability).to be_able_to(:read, EventType)
      expect(ability).to be_able_to(:read, Article)
    end

    it 'can create content models' do
      expect(ability).to be_able_to(:create, Event)
      expect(ability).to be_able_to(:create, EventType)
      expect(ability).to be_able_to(:create, Article)
      expect(ability).to be_able_to(:create, Resource)
    end

    it 'can update content models' do
      expect(ability).to be_able_to(:update, Event)
      expect(ability).to be_able_to(:update, EventType)
      expect(ability).to be_able_to(:update, Article)
      expect(ability).to be_able_to(:update, Resource)
    end

    it 'can set publishing fields' do
      expect(ability).to be_able_to(:set_include_in_catalog, EventType)
      expect(ability).to be_able_to(:set_published, Article)
      expect(ability).to be_able_to(:set_published, Resource)
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

    it 'cannot read, create, update, or destroy resources' do
      expect(ability).not_to be_able_to(:read, Event)
      expect(ability).not_to be_able_to(:create, Event)
      expect(ability).not_to be_able_to(:update, Event)
      expect(ability).not_to be_able_to(:destroy, Event)
    end
  end
end
