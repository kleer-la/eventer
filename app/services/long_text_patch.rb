# frozen_string_literal: true

# The in-place edit behind the MCP write tools: changing one phrase of a long
# text without fetching the whole thing and sending it back.
#
# Every replacement is checked before anything is written: a `find` that matches
# nothing, or matches more than once without `all`, is an error and the whole
# call fails. That is the point — a caller working from a stale or half-
# remembered copy of the text finds out, instead of quietly editing the wrong
# sentence. Replacements run in order, each against the text the previous one
# left, so several edits to the same field compose.
class LongTextPatch
  # How much text to keep around an edit, so the preview reads like the change
  # and not like the beginning of the field.
  CONTEXT = 80
  QUOTE_LIMIT = 200

  # patchable: names of the fields that accept a patch; given: names the caller
  # also sent whole; current: the text of a field as it stands today.
  def initialize(specs, patchable:, given: [], current: nil)
    # symbolize_keys because fast-mcp only symbolises the top level of a tool's
    # arguments: a hash nested inside an array arrives with string keys.
    @specs = Array(specs).map { |spec| spec.to_h.symbolize_keys }
    @patchable = patchable.map(&:to_s)
    @given = given.map(&:to_s)
    @current = current || ->(_field) { '' }
    @fields = {}
    @applied = Hash.new { |hash, field| hash[field] = [] }
    @errors = []
  end

  attr_reader :fields, :applied, :errors

  def apply
    @specs.each { |spec| apply_one(spec) }
    self
  end

  private

  def apply_one(spec)
    field = spec[:field].to_s
    return @errors << unpatchable(field) unless @patchable.include?(field)
    return @errors << "Pass either #{field} or a replacement for it, not both" if conflicting?(field)

    text = text_for(field)
    occurrences = text.scan(spec[:find].to_s).size
    return @errors << mismatch(spec, field, occurrences) unless matched?(spec, occurrences)

    replace(field, text, spec, occurrences)
  end

  def replace(field, text, spec, occurrences)
    find = spec[:find].to_s
    new_text = spec[:replace].to_s
    # The block form of sub/gsub: the new text goes in literally, instead of a
    # \1 or a \\ inside it meaning something to the regexp engine.
    @fields[field] = spec[:all] ? text.gsub(find) { new_text } : text.sub(find) { new_text }
    @applied[field] << { find: find, replace: new_text, occurrences: spec[:all] ? occurrences : 1,
                         context: context_around(text, find, new_text) }
  end

  def matched?(spec, occurrences) = occurrences == 1 || (spec[:all] && occurrences.positive?)

  # A field already patched carries the result of the previous replacement.
  def text_for(field) = @fields.key?(field) ? @fields[field] : @current.call(field).to_s

  def conflicting?(field) = @given.include?(field) && !@fields.key?(field)

  def unpatchable(field)
    return "Cannot replace text in #{field}: this content has no long text fields" if @patchable.empty?

    "Cannot replace text in #{field}: it is not a long text field. " \
      "Fields that take replacements: #{@patchable.join(', ')}"
  end

  def mismatch(spec, field, occurrences)
    quoted = spec[:find].to_s.truncate(QUOTE_LIMIT).inspect
    return "No match for #{quoted} in #{field}" if occurrences.zero?

    "#{quoted} appears #{occurrences} times in #{field}: make it unique by including more of the " \
      'surrounding text, or pass all: true to replace every one'
  end

  # The edit as it will read, with enough text around it to recognise the place.
  def context_around(text, find, new_text)
    at = text.index(find)
    from = [at - CONTEXT, 0].max
    edited = "#{text[from...at]}#{new_text}#{text[(at + find.length)..]}"
    excerpt = edited[0, (at - from) + new_text.length + CONTEXT]
    "#{'…' if from.positive?}#{excerpt}#{'…' if excerpt.length < edited.length}"
  end
end
