# frozen_string_literal: true

# The site builds a page's outcomes out of ul > li, and its program and FAQ out
# of ol > li items, each with a nested ul > li detail (ServiceOffering). Any
# other HTML saves fine and then the section is simply missing from the page,
# so a write that brings a block the site cannot read says so in the preview.
# A block the site can read may still have items it shows broken — a question
# in <strong> that the page cuts, a FAQ entry with no answer — and those are
# named one by one.
module OfferingFormatWarnings
  LIST_BLOCKS = {
    outcomes: 'ul > li, e.g. <ul><li>…</li></ul>',
    program: 'ol > li with the detail in a nested ul > li, e.g. <ol><li>Step<ul><li>Detail</li></ul></li></ol>',
    faq: 'ol > li with the answer in a nested ul > li, e.g. <ol><li>Question?<ul><li>Answer</li></ul></li></ol>'
  }.freeze

  private

  def offering_format_warnings
    list_shape_warnings + outside_list_warnings + rendered_html_warnings
  end

  # Of a list block the site gets only the items: a separator, a paragraph or
  # a client case after the list saves fine and never reaches the page.
  LIST_CONTAINERS = { outcomes: 'ul', program: 'ol', faq: 'ol' }.freeze
  # Markup that only wraps or spaces, which leaves nothing behind when removed
  WRAPPERS = %w[div br].freeze

  def outside_list_warnings
    LIST_CONTAINERS.filter_map do |block, container|
      next unless @fields.key?(block) && @record.public_send(block).present?

      left = left_outside(@record.public_send(block).body.to_html, container)
      next if left.empty?

      "#{block}: the site shows only its #{container} > li items, so this is left out of the page: #{left.join(', ')}"
    end
  end

  def left_outside(html, container)
    doc = Nokogiri::HTML5.fragment(html)
    doc.css(container).each(&:remove)
    elements = doc.css('*').map(&:name).uniq - WRAPPERS
    text = doc.text.squish
    elements.map { |tag| "<#{tag}>" } + (text.empty? ? [] : ["«#{text.truncate(80)}»"])
  end

  # The prose blocks reach the page rendered by ActionText, which drops what
  # its safe list does not allow (SiteRenderedHtml). Keventer keeps it all.
  def rendered_html_warnings
    (self.class.rich_text_fields - LIST_BLOCKS.keys).filter_map do |block|
      next unless @fields.key?(block)

      dropped = SiteRenderedHtml.new(@fields[block]).dropped
      next if dropped.empty?

      "#{block}: the site does not show #{dropped.join(', ')}. Keventer keeps it, but the page renders a " \
        'safe list of HTML (no inline styles, data-* attributes, iframes or tables): use plain markup instead'
    end
  end

  def list_shape_warnings
    LIST_BLOCKS.flat_map do |block, shape|
      next [] unless @fields.key?(block) && @record.public_send(block).present?
      next broken_item_warnings(block) if items_of(block).any?

      ["The #{block} block has no items the site can show, so that section will not appear " \
       "on the page. It needs #{shape}"]
    end
  end

  def broken_item_warnings(block)
    return [] if block == :outcomes

    @record.list_items(block).each_with_index.flat_map do |item, index|
      item_warnings(block, item, "#{block} item #{index + 1}")
    end
  end

  def item_warnings(block, item, name)
    [cut_title_warning(item, name), (missing_answer_warning(name) if block == :faq && item.css('ul > li').empty?)]
      .compact
  end

  def cut_title_warning(item, name)
    shown = ServiceOffering.item_title(item)
    text = item.dup.tap { |copy| copy.css('ul').remove }.text.squish
    return if shown == text

    "#{name} shows on the page as #{shown.inspect}, but its text is #{text.inspect}: write it as " \
      'plain text, without bold or links, before the nested list'
  end

  def missing_answer_warning(name)
    "#{name} has no answer: it goes in a nested ul > li, e.g. <ol><li>Question?<ul><li>Answer</li></ul></li></ol>"
  end

  def items_of(block)
    case block
    when :outcomes then Array(@record.outcomes_list)
    when :program then @record.program_list.reject { |main, _| main.blank? }
    when :faq then @record.faq_list.reject { |main, _| main.blank? }
    end
  end
end
