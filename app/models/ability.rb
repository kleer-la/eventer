# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.role? :administrator
      can :manage, :all #[Role, User, Event, Trainer, EventType, Category, Setting, OauthToken, Log]
    elsif user.role? :comercial
      can :manage, [Event]
    end

    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'
  end
end
