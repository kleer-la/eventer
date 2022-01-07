# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.role? :administrator
      can :manage, [Role, User, Event, Trainer, EventType, Category, Setting, OauthToken]
    elsif user.role? :comercial
      can :manage, [Event]
    end
  end
end
