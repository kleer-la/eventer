# frozen_string_literal: true

class String
  def is_integer?
    true if Integer(self)
  rescue StandardError
    false
  end
end
