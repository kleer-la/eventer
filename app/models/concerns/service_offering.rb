# frozen_string_literal: true

# The blocks that make an offering sellable on its page — outcomes, program,
# definitions, FAQ — and how the site reads them: outcomes as a bullet list,
# program and FAQ as numbered items each with an optional collapsible detail.
# A Service has always had them; a ServiceArea carries them too, so an area
# can be presented and bought without a service underneath.
module ServiceOffering
  extend ActiveSupport::Concern

  included do
    has_rich_text :outcomes
    has_rich_text :definitions
    has_rich_text :program
    has_rich_text :faq
  end

  def outcomes_list
    return nil unless outcomes.present?

    doc = Nokogiri::HTML(outcomes.body.to_html)
    doc.css('ul li').map(&:inner_html)
  end

  def program_list
    field_list(:program)
  end

  def faq_list
    field_list(:faq)
  end

  # The ol > li items of the program or FAQ block, as the site reads them.
  def list_items(block)
    field = public_send(block)
    return [] unless field.present?

    Nokogiri::HTML(field.body.to_html).css('ol > li')
  end

  # What the site shows as an item's step or question: its first bare text.
  # Text inside markup (a <strong>, a link) is not part of it.
  def self.item_title(item) = item.at_css('> text()').to_s.strip

  private

  def field_list(block)
    list_items(block).map do |li|
      collapsible_items = li.css('ul > li').map { |item| item.inner_html.strip }
      [ServiceOffering.item_title(li), collapsible_items[0]]
    end
  end
end
