# frozen_string_literal: true

# A resource's own English slug (#227). Optional: without it, English uses the
# Spanish slug, and it may also be the same as the Spanish one. No slug of a
# resource — Spanish, English, current or old — may be one of another
# resource, so any of them finds a single one. An English slug it leaves is
# remembered in friendly_id's history with scope 'en': the history finder
# matches any scope, so the old URL keeps resolving and the site answers 301.
module EnglishSlug
  extend ActiveSupport::Concern

  included do
    before_validation { self.slug_en = slug_en&.strip.presence }
    validates :slug_en, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :slug_format }, allow_nil: true
    validate :slugs_of_no_other_resource
    before_update :remember_slug_en_being_left
  end

  class_methods do
    def find_by_any_slug(slug)
      find_by(slug:) || find_by(slug_en: slug) || friendly.find(slug)
    end
  end

  def slug_for(lang) = lang.to_s == 'en' ? slug_en.presence || slug : slug

  private

  def slugs_of_no_other_resource
    { slug: slug, slug_en: slug_en }.each do |field, value|
      next if value.blank? || !(field == :slug ? slug_changed? : slug_en_changed?)

      other = holder_of(value)
      errors.add(field, :taken_by, slug: value, resource: other.title_es) if other
    end
  end

  def holder_of(value)
    others = self.class.where.not(id:)
    others.find_by(slug: value) || others.find_by(slug_en: value) ||
      others.joins(:slugs).find_by(friendly_id_slugs: { slug: value })
  end

  def remember_slug_en_being_left
    return unless slug_en_changed? && slug_en_was.present?

    slugs.find_or_create_by!(slug: slug_en_was, scope: 'en')
  end
end
