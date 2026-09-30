# frozen_string_literal: true

# A content write runs in a savepoint that only survives a confirmed save.
# Assigning an association to a saved record (trainers, a
# has_and_belongs_to_many) writes at once, so a preview or a failed validation
# has to roll it back. requires_new makes it a real savepoint even inside an
# outer transaction.
module WriteInSavepoint
  def call(...)
    result = nil
    self.class.model.transaction(requires_new: true) do
      result = super
      raise ActiveRecord::Rollback unless result[:status] == 'saved'
    end
    result
  end
end
