# frozen_string_literal: true

class Ability
  include CanCan::Ability

  # Models under "Courses Mgnt" menu
  COURSES_MGNT_MODELS = [Event, EventType, Participant, Coupon].freeze

  # Models under "We Publish" menu
  WE_PUBLISH_MODELS = [Article, Resource, Podcast, Episode, Assessment, News, RecommendedContent].freeze

  # Content role models (Courses Mgnt + We Publish + Testimony + Images)
  CONTENT_MODELS = (COURSES_MGNT_MODELS + WE_PUBLISH_MODELS + [Testimony]).freeze

  def initialize(user)
    user ||= User.new

    # Alias custom actions to CRUD actions
    alias_action :copy, to: :create

    # All roles can read dashboard
    can :read, ActiveAdmin::Page, name: 'Dashboard', namespace_name: 'admin'

    return unless user.roles.any?

    # All roles can read everything
    can :read, :all

    # Comercial: only read (already granted above)

    # Content: read + create/update specific models, but cannot set publishing fields
    if user.role?(:content)
      can %i[create update], CONTENT_MODELS
      can :manage, ActiveAdmin::Page, name: 'Images', namespace_name: 'admin'

      # Cannot set publishing fields
      cannot :set_include_in_catalog, EventType
      cannot :set_published, [Article, Resource]
    end

    # Publisher: same as content + can set publishing fields
    if user.role?(:publisher)
      can %i[create update], CONTENT_MODELS
      can :manage, ActiveAdmin::Page, name: 'Images', namespace_name: 'admin'
      can :set_include_in_catalog, EventType
      can :set_published, [Article, Resource]
    end

    # Marketing: read, create, update all
    if user.role?(:marketing)
      can :create, :all
      can :update, :all
    end

    # Administrator: full access including destroy
    if user.role?(:administrator)
      can :manage, :all
    end
  end
end
