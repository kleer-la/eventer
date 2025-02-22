class Section < ApplicationRecord
  belongs_to :page
  extend FriendlyId
  friendly_id :title, use: %i[slugged scoped], scope: :page_id

  validates :slug, uniqueness: { scope: :page_id }

  def should_generate_new_friendly_id?
    title_changed? || new_record?
  end

  def resolve_friendly_id_conflict(candidates)
    candidates.first # Return the original slug without modification
  end
end
