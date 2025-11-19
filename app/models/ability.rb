# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.role? :administrator
      can :manage, :all
    elsif user.role?(:comercial) || user.role?(:marketing) || user.role?(:content)
      can :read, :all
      can :create, :all
      can :update, :all
      cannot :destroy, :all
    end

    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
  end
end
