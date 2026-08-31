# frozen_string_literal: true

# Base for every MCP tool. Resolves the user behind the OAuth token in the
# Authorization header so tools answer with the same permissions the admin
# screens would give that person.
class ApplicationTool < ActionTool::Base
  # How much of a listing to return. A tool whose collection needs different
  # sizes overrides them; `listing` reads them off the tool's own class.
  DEFAULT_LIMIT = 25
  MAX_LIMIT = 100

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

  # The envelope every list_* tool answers with. `total` is the whole point: a
  # caller that sees 25 of 137 can narrow the search, while a bare list of 25
  # reads as the whole world — and "not in the first 25" comes back to the user
  # as "does not exist". The note says it in words as well as numbers, because
  # words are what get acted on.
  #
  # `items` are already summarised; `narrow` names this tool's own filters.
  def listing(key, items, total:, narrow:)
    envelope = { returned: items.size, total: total }
    if total > items.size
      envelope[:truncated] = true
      envelope[:note] = "#{total} matched; these are the first #{items.size}. Narrow the search with " \
                        "#{narrow}, or raise limit (max #{self.class::MAX_LIMIT})."
    end
    envelope.merge(key => items).to_json
  end

  # fast-mcp hands the tool whatever the caller sent, and dry-schema quietly
  # ignores keys the tool never declared, so an argument with no matching
  # keyword reached `call` and raised ArgumentError — which the server passed
  # back to the client as a Ruby backtrace. Answer with the argument's name and
  # the ones this tool does take: a caller that guessed wrong can then fix it.
  def call_with_schema_validation!(**args)
    unknown = args.keys.map(&:to_s) - known_arguments
    return [unknown_arguments(unknown), _meta] if unknown.any?

    super
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = OauthAccess.authenticate(bearer_token)
  end

  def ability
    @ability ||= Ability.new(current_user)
  end

  private

  def known_arguments = self.class.input_schema.key_map.map(&:name)

  def unknown_arguments(unknown)
    { status: 'error',
      errors: ["Unknown argument#{'s' if unknown.size > 1} #{unknown.map(&:inspect).join(', ')}. " \
               "#{self.class.tool_name} takes: #{known_arguments.join(', ')}"] }.to_json
  end

  def bearer_token
    headers['authorization']&.delete_prefix('Bearer ')
  end
end
