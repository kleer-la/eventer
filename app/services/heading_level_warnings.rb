# frozen_string_literal: true

# A write service names, in `heading_starts`, the long fields the site renders
# under a heading of its own and the level their headings start at; a write
# that changes one of them warns about its first heading out of place
# (ContentHeadings). The levels come from website17's templates: an article
# body sits right under the page's h1, a course's recipients under their
# section's h2. Fields whose headings mean something else (a course FAQ splits
# its questions on h4) are left out (kleer-la/website17#466).
module HeadingLevelWarnings
  extend ActiveSupport::Concern

  included do
    class_attribute :heading_starts, default: {}
  end

  private

  def heading_level_warnings
    heading_starts.filter_map do |field, start|
      next unless @record.changed.include?(field.to_s)

      problem = ContentHeadings.new(@record.public_send(field)).problem(start: start)
      next unless problem

      "Heading levels in #{field}: #{problem}. Otherwise the page's outline breaks for search engines " \
        'and screen readers.'
    end
  end
end
