# frozen_string_literal: true

# The `clear` argument of the MCP write tools: names of fields to empty. The
# text arguments are filled(:string), so an empty string is not a value a
# caller can send. Emptied fields join the given ones, so the preview and the
# validations see them like any other change; ActionText blocks take "".
module ClearableFields
  def initialize(clear: nil, **args)
    @clear = Array(clear).map(&:to_sym)
    super(**args)
  end

  private

  def apply_clear
    return if @clear.empty?
    return errors << clear_refusal if clear_refusal

    @fields.merge!(@clear.index_with { |field| self.class.rich_text_fields.include?(field) ? '' : nil })
  end

  def clear_refusal
    editable = self.class.editable_fields
    unknown = @clear - editable
    return "Cannot clear #{unknown.join(', ')}. Fields that can be cleared: #{editable.join(', ')}" if unknown.any?

    given = @clear & @fields.keys
    "#{given.join(', ')} given a value and cleared at once: choose one" if given.any?
  end
end
