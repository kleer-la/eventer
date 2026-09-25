# frozen_string_literal: true

# FriendlyId's history records a slug when it becomes the current one, so a
# record older than the history, or renamed outside Rails, has no row for the
# slug it is leaving. Remember it before it goes: the old URL keeps resolving,
# and the site can answer it with a 301 (kleer-la/eventer#208).
module KeepsSlugHistory
  extend ActiveSupport::Concern

  included do
    before_update :remember_slug_being_left
  end

  private

  def remember_slug_being_left
    return unless slug_changed? && slug_was.present?
    return if slugs.exists?(slug: slug_was)

    slugs.create!(slug: slug_was)
  end
end
