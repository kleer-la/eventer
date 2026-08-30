# frozen_string_literal: true

# The `changes` block an MCP write tool shows before saving: a chat-sized
# account of what the write would do. Long texts are summarised — echoing a
# six-thousand-character body back would drown the preview — and a field edited
# in place is shown as the edits themselves, because the beginning of a long
# text says nothing about a change buried in its middle.
class ContentChangePreview
  LONG_FIELD_PREVIEW = 200

  # long: fields summarised instead of echoed; before: the ActionText ones and
  # the text they held before the write, since their changes never reach
  # record.changes; applied: what each in-place replacement did, by field.
  def initialize(record, fields:, long:, before: {}, applied: {})
    @record = record
    @fields = fields
    @long = long.map(&:to_s)
    @before = before
    @applied = applied
  end

  def to_h = attribute_changes.merge(rich_text_changes)

  private

  def attribute_changes
    @record.changes.to_h do |field, (before, after)|
      [field, @long.include?(field) ? long_change(field, before, after) : { from: before, to: after }]
    end
  end

  # ActionText lives in its own table, so a change to it never shows up in
  # record.changes; report it from what the caller actually passed.
  def rich_text_changes
    @before.select { |field, _| @fields.key?(field.to_sym) }
           .to_h { |field, before| [field, long_change(field, before, @fields[field.to_sym])] }
  end

  def long_change(field, before, after)
    summary = { from_length: before.to_s.length, to_length: after.to_s.length }
    return summary.merge(replacements: @applied[field]) if @applied.key?(field)

    summary.merge(new_beginning: after.to_s.truncate(LONG_FIELD_PREVIEW))
  end
end
