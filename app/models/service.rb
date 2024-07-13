# frozen_string_literal: true

class Service < ApplicationRecord
  include Recommendable
  before_save :strip_slug
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]
  belongs_to :service_area
  has_many :testimonies

  has_rich_text :value_proposition
  has_rich_text :outcomes
  has_rich_text :definitions
  has_rich_text :program
  has_rich_text :target
  has_rich_text :faq

  validates_presence_of %i[name subtitle value_proposition outcomes program target side_image]

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id name slug service_area_id subtitle updated_at value_proposition outcomes program target faq]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[rich_text_definitions rich_text_faq rich_text_outcomes rich_text_program rich_text_target
       rich_text_value_proposition service_area testimonies]
  end

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def outcomes_list
    return nil unless outcomes.present?

    doc = Nokogiri::HTML(outcomes.body.to_html)
    doc.css('ul li').map(&:inner_html)
  end

  def program_list
    field_list(program)
  end

  def faq_list
    field_list(faq)
  end

  def as_recommendation
    super
      .merge('title' => name)
      .merge('description' => subtitle)
      .merge('cover' => side_image)
  end

  private

  def field_list(field)
    return [] unless field.present?

    doc = Nokogiri::HTML(field.body.to_html)
    doc.css('ol > li').map do |li|
      main_item = li.at_css('> text()').to_s.strip
      collapsible_items = li.css('ul > li').map(&:text).map(&:strip)
      [main_item, collapsible_items[0]]
    end
  end

  def strip_slug
    slug.strip! if slug.present?
  end
end
