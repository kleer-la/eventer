module Recommendable
  extend ActiveSupport::Concern

  included do
    has_many :recommended_contents, as: :source
    has_many :recommended_items, -> { distinct }, through: :recommended_contents, source: :target, source_type: 'Article'
  end

  def as_recommendation
    as_json(only: %i[id title subtitle slug cover])
      .merge('type' => self.class.name.underscore)
  end

  def recommended
    recommended_contents.includes(:target).order(:relevance_order).map do |content|
      content.target.as_recommendation
    end
  end
end
