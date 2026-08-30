# frozen_string_literal: true

# Base for every MCP tool. Resolves the user behind the OAuth token in the
# Authorization header so tools answer with the same permissions the admin
# screens would give that person.
class ApplicationTool < ActionTool::Base
  # The in-place edit argument, identical in every write tool that has long text
  # fields. `arguments` takes a dry-schema DSL block, instance_eval'd on the
  # schema where a method of the tool class is out of reach, so the tools splice
  # it in with `instance_exec(&ApplicationTool::REPLACEMENTS)` and name their own
  # patchable fields in their description.
  REPLACEMENTS = lambda do
    optional(:replacements).array(:hash) do
      required(:field).filled(:string).description('Long text field to edit in place')
      required(:find).filled(:string)
                     .description('Exact text to look for, copied from the current text')
      optional(:replace).value(:string).description('Text to put in its place. An empty string deletes it')
      optional(:all).filled(:bool)
                    .description('true = replace every occurrence instead of failing on an ambiguous find')
    end.description(
      'Edits long text in place instead of resending it whole: each entry replaces `find` with `replace` ' \
      'inside `field`, in order. Prefer it to sending the entire field when you are changing part of it. ' \
      'Nothing is saved if a `find` matches no text, or matches more than once without `all`, so read the ' \
      'current text first and copy from it.'
    )
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = OauthAccess.authenticate(bearer_token)
  end

  def ability
    @ability ||= Ability.new(current_user)
  end

  private

  def bearer_token
    headers['authorization']&.delete_prefix('Bearer ')
  end
end
