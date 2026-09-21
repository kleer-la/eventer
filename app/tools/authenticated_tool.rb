# frozen_string_literal: true

# Base for tools that need an identified user: the server answers
# 'Unauthorized' before running `call` when the OAuth token resolves to nobody.
#
# Per-resource permissions are declared on each tool with
# `requires_permission :update, Article` and checked against ability.rb, the
# same rules the screens use: whoever cannot do it in the admin cannot do it
# from the chat either.
class AuthenticatedTool < ApplicationTool
  authorize { current_user.present? }

  # Adds a CanCanCan check to the tool's authorization pipeline. Blocks
  # accumulate (fast-mcp evaluates every block in the hierarchy with `all?`),
  # so the "user present" check stays in force.
  def self.requires_permission(action, subject)
    authorize { ability.can?(action, subject) }
  end

  # Tools that bundle several operations (`operation: list | get | ...`) are
  # authorized for reading as a whole and check each write here, with the
  # same rules ability.rb gives the admin screens.
  def unauthorized(action, subject)
    error("Unauthorized: you are not allowed to #{action} #{subject.model_name.human.downcase.pluralize}")
  end

  def unknown_operation(operation)
    error("Unknown operation #{operation.inspect}. Valid ones: #{self.class::OPERATIONS.join(', ')}")
  end
end
