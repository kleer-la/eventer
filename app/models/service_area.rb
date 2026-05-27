# frozen_string_literal: true

class ServiceArea < ApplicationRecord
  before_save :strip_slug
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]

  include ImageReference
  references_images_in :icon, :side_image

  enum :lang, { es: 0, en: 1 }
  has_many :services, dependent: :destroy
  has_and_belongs_to_many :trainers

  has_rich_text :summary
  has_rich_text :slogan
  has_rich_text :subtitle
  has_rich_text :description
  has_rich_text :target
  has_rich_text :value_proposition
  has_rich_text :cta_message

  validates_presence_of %i[
    name summary icon slogan subtitle description side_image
    primary_color secondary_color cta_message
    seo_title seo_description
  ]

  def should_generate_new_friendly_id?
    slug.blank?
  end

  def testimonies
    Testimony.where(testimonial_type: 'Service', testimonial_id: service_ids)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[abstract created_at icon id id_value lang name primary_color secondary_color slug updated_at visible
       recommended_way_title recommended_way_note]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[services trainers]
  end

  def recommended_way_summary_html
    render_markdown(recommended_way_summary)
  end

  def recommended_way_details_html
    render_markdown(recommended_way_details)
  end

  private

  def render_markdown(source)
    return nil if source.blank?

    # Matches the Redcarpet + HTML approach already used for Trainer long_bio in ActiveAdmin
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: false),
      tables: true,
      autolink: true,
      fenced_code_blocks: true,
      strikethrough: true
    )
    markdown.render(source)
  end

  def strip_slug
    slug.strip! if slug.present?
  end
end
