# frozen_string_literal: true

# The headings of a long text field, markdown (`## Title`) and HTML (`<h2>`)
# alike, in the order they appear, and the first one that breaks the outline of
# the page it is shown on. The site renders the field under a heading of its
# own, so its headings start one level below that one (`start`) and go down a
# level at a time, as website17's HeadingOutline checks on the rendered page.
#
# The site's markdown renderer reads `##Title`, without the space, as a heading
# too, so it is counted.
class ContentHeadings
  MARKDOWN = /^ {0,3}(?<marks>\#{1,6})(?!#)[ \t]*(?<title>.*?)[ \t#]*$/
  HTML = %r{<h(?<level>[1-6])\b[^>]*>(?<title>.*?)</h\k<level>\s*>}im

  Heading = Data.define(:level, :title, :position)

  def initialize(text)
    @text = text.to_s
  end

  def headings
    (markdown_headings + html_headings).sort_by(&:position)
  end

  # The first heading out of place, as a sentence, or nil.
  def problem(start:)
    previous = start - 1
    headings.each do |heading|
      return above(heading, start) if heading.level < start
      return skipped(heading, previous) if heading.level > previous + 1

      previous = heading.level
    end
    nil
  end

  private

  def markdown_headings
    matches(MARKDOWN).map { |m| Heading.new(m[:marks].length, plain(m[:title]), m.begin(0)) }
  end

  def html_headings
    matches(HTML).map { |m| Heading.new(m[:level].to_i, plain(m[:title]), m.begin(0)) }
  end

  def matches(pattern) = @text.to_enum(:scan, pattern).map { Regexp.last_match }

  def plain(title) = ActionController::Base.helpers.strip_tags(title).squish.truncate(60)

  def above(heading, start)
    "«#{heading.title}» is an h#{heading.level}, but here headings start at h#{start}: " \
      "the page already has its h#{start - 1} above this text"
  end

  def skipped(heading, previous)
    "«#{heading.title}» is an h#{heading.level} right after an h#{previous}, skipping a level: " \
      "make it an h#{previous + 1}"
  end
end
