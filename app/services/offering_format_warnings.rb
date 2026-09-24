# frozen_string_literal: true

# The site builds a page's outcomes out of ul > li, and its program and FAQ out
# of ol > li items, each with a nested ul > li detail (ServiceOffering). Any
# other HTML saves fine and then the section is simply missing from the page,
# so a write that brings a block the site cannot read says so in the preview.
module OfferingFormatWarnings
  LIST_BLOCKS = {
    outcomes: 'ul > li, e.g. <ul><li>…</li></ul>',
    program: 'ol > li with the detail in a nested ul > li, e.g. <ol><li>Step<ul><li>Detail</li></ul></li></ol>',
    faq: 'ol > li with the answer in a nested ul > li, e.g. <ol><li>Question?<ul><li>Answer</li></ul></li></ol>'
  }.freeze

  private

  def offering_format_warnings
    LIST_BLOCKS.filter_map do |block, shape|
      next unless @fields.key?(block) && @record.public_send(block).present?
      next if items_of(block).any?

      "The #{block} block has no items the site can show, so that section will not appear " \
        "on the page. It needs #{shape}"
    end
  end

  def items_of(block)
    case block
    when :outcomes then Array(@record.outcomes_list)
    when :program then @record.program_list.reject { |main, _| main.blank? }
    when :faq then @record.faq_list.reject { |main, _| main.blank? }
    end
  end
end
