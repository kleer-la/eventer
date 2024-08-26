# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  included do
    has_many :recommended_contents, as: :source
    has_many :recommended_items, lambda {
                                   distinct
                                 }, through: :recommended_contents, source: :target, source_type: 'Article'
  end

  def as_recommendation
    as_json(only: %i[id title subtitle slug cover])
      .merge('type' => self.class.name.underscore)
  end

  def recommended
    recommended_contents.includes(:target).order(:relevance_order).map do |content|
      content.target.as_recommendation.merge('relevance_order' => content.relevance_order)
    end
  end

  class_methods do
    def recommended_content_targets
      {
        'Article' => Article.all.order(:title).pluck(:title, :id),
        'EventType' => EventType.included_in_catalog.order(:name).map { |et| [et.unique_name, et.id] },
        'Service' => Service.all.order(:name).pluck(:name, :id),
        'Resource' => Resource.all.order(:title_es).pluck(:title_es, :id)
      }
    end
  end
end
