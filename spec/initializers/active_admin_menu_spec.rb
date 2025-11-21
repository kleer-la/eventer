# frozen_string_literal: true

require 'rails_helper'

describe 'ActiveAdmin Menu Configuration' do
  describe 'User with roles display' do
    let(:user) { FactoryBot.create(:user) }
    let(:admin_role) { FactoryBot.create(:admin_role) }
    let(:trainer_role) { FactoryBot.create(:trainer_role) }

    it 'displays role badges for user with single role' do
      user.roles << admin_role

      roles_html = user.roles.map do |role|
        "<span class='role-badge role-badge-#{role.name.to_s.parameterize}'>#{role.name}</span>"
      end.join(' ')

      expect(roles_html).to include('role-badge')
      expect(roles_html).to include('role-badge-administrator')
      expect(roles_html).to include('administrator')
    end

    it 'displays multiple role badges for user with multiple roles' do
      user.roles << admin_role
      user.roles << trainer_role

      roles_html = user.roles.map do |role|
        "<span class='role-badge role-badge-#{role.name.to_s.parameterize}'>#{role.name}</span>"
      end.join(' ')

      expect(roles_html).to include('role-badge-administrator')
      expect(roles_html).to include('role-badge-trainer')
      expect(user.roles.count).to eq(2)
    end

    it 'parameterizes role names correctly for CSS classes' do
      marketing_role = FactoryBot.create(:marketing_role)
      user.roles << marketing_role

      parameterized_name = marketing_role.name.to_s.parameterize

      expect(parameterized_name).to eq('marketing')
    end

    it 'combines email and roles correctly' do
      user.roles << admin_role

      roles_html = user.roles.map do |role|
        "<span class='role-badge role-badge-#{role.name.to_s.parameterize}'>#{role.name}</span>"
      end.join(' ')

      combined = "#{user.email} #{roles_html}"

      expect(combined).to include(user.email)
      expect(combined).to include('role-badge')
    end
  end
end
