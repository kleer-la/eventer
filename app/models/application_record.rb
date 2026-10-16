# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # The records whose `columns` contain `text`, whatever its case: what the MCP
  # list tools filter `query` with. A column is a symbol of this model or an Arel
  # attribute of a joined table. LIKE alone does not do: SQLite matches ASCII
  # case-insensitively, PostgreSQL (QA, production) does not, so Arel asks it for
  # ILIKE. `%` and `_` in `text` are plain characters.
  def self.matching(text, *columns)
    pattern = "%#{sanitize_sql_like(text.to_s)}%"
    conditions = columns.map { |column| (column.is_a?(Symbol) ? arel_table[column] : column).matches(pattern, '\\') }
    where(conditions.reduce(:or))
  end
end
