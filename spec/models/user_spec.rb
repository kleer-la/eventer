# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe User do
  context 'Role association' do
    it 'can have multiple roles' do
      user = FactoryBot.create(:user)
      admin_role = FactoryBot.create(:admin_role)
      trainer_role = FactoryBot.create(:trainer_role)

      user.roles << admin_role
      user.roles << trainer_role

      expect(user.roles.count).to eq(2)
      expect(user.roles).to include(admin_role, trainer_role)
    end

    it 'returns role names correctly' do
      user = FactoryBot.create(:user)
      admin_role = FactoryBot.create(:admin_role)

      user.roles << admin_role

      expect(user.roles.first.name).to eq('admin')
    end
  end

  context "If it's an administrator" do
    before(:each) do
      user = FactoryBot.create(:user)
      user.roles << FactoryBot.create(:admin_role)
      @admin = Ability.new user
      #      @admin = Ability.new FactoryBot.create(:administrator) # doesn't work idk why
    end

    it { expect(@admin).to be_able_to(:manage, Role.new) }
    it { expect(@admin).to be_able_to(:manage, User.new) }
    it { expect(@admin).to be_able_to(:manage, Event.new) }
    it { expect(@admin).to be_able_to(:manage, Trainer.new) }
    it { expect(@admin).to be_able_to(:manage, Category.new) }
  end

  context "If it's a comercial person" do
    before(:each) do
      user = FactoryBot.create(:user)
      user.roles << FactoryBot.create(:comercial_role)
      @comercial = Ability.new user
    end

    it { expect(@comercial).not_to be_able_to(:manage, Role.new) }
    it { expect(@comercial).not_to be_able_to(:manage, User.new) }
    it { expect(@comercial).to be_able_to(:read, Event.new) }
    it { expect(@comercial).not_to be_able_to(:create, Event.new) }
    it { expect(@comercial).not_to be_able_to(:update, Event.new) }
    it { expect(@comercial).not_to be_able_to(:destroy, Event.new) }
    it { expect(@comercial).to be_able_to(:read, EventType.new) }
    it { expect(@comercial).not_to be_able_to(:manage, Category.new) }
    it { expect(@comercial).not_to be_able_to(:manage, Trainer.new) }
  end
end
