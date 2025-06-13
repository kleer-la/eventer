# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  included do
    has_many :recommended_contents, as: :source
    has_many :recommended_items, lambda {
                                   distinct
                                 }, through: :recommended_contents, source: :target, source_type: 'Article'
  end

  def calculate_level(relevance_order)
    case relevance_order
    when 0...100
      'initial'
    when 100...200
      'intermediate'
    else
      'advanced'
    end
  end

  def as_recommendation(lang: 'es')
    as_json(only: %i[id title subtitle slug cover])
      .merge('type' => self.class.name.underscore)
  end

  def recommended(lang: 'es')
    recommended_contents.preload(:target).order(:relevance_order).map do |content|
      next unless content.target.present? # Skip if target is nil

      content.target.as_recommendation(lang:).merge('relevance_order' => content.relevance_order,
                                                    'level' => calculate_level(content.relevance_order))
    end.compact
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
