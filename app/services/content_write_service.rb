# frozen_string_literal: true

# Shared machinery for the MCP write tools: assign the given fields, validate,
# return a preview that persists nothing, and only save on confirm.
#
# It also carries the publishing guard. `published` is the one rule ability.rb
# expresses outside plain CRUD (`cannot :set_published`), so it never travels
# with the rest of the fields: a content user can draft and edit but not
# publish, the same line the admin forms draw.
class ContentWriteService
  LONG_FIELD_PREVIEW = 200

  class << self
    # Subclasses declare what they write: the model, the fields a tool may set,
    # and which of those are long enough to summarise instead of echoing.
    attr_accessor :model, :editable_fields, :long_fields
  end
  self.long_fields = []

  def initialize(ability:, record: nil, category: nil, published: nil, **fields)
    @ability = ability
    @record = record || self.class.model.new
    @category = category
    @published = published
    @fields = fields.slice(*self.class.editable_fields).compact
  end

  def call(confirm: false)
    assign
    return failure if errors.any? || !@record.valid?

    saved_warnings = warnings # computed before saving: afterwards nothing is dirty
    return preview unless confirm

    @record.save!
    { status: 'saved', id: @record.id, slug: @record.slug, title: @record.title,
      published: @record.published, admin_path: admin_path, warnings: saved_warnings }
  end

  private

  def assign
    @record.assign_attributes(@fields)
    assign_category
    assign_published
  rescue ArgumentError => e
    # An enum (Resource#format) rejecting a value it does not know
    errors << e.message
  end

  def assign_category
    return if @category.blank?

    category = Category.find_by(name: @category)
    return errors << "Unknown category #{@category.inspect}. Existing ones: #{Category.pluck(:name).join(', ')}" if category.nil?

    @record.category = category
  end

  def assign_published
    return if @published.nil? || @published == @record.published

    return errors << 'You are not allowed to change whether this is published' unless @ability.can?(:set_published, self.class.model)

    @record.published = @published
  end

  def preview
    { status: 'preview', changes: changes, warnings: warnings,
      note: 'Nothing was saved. Call again with confirm=true to apply these changes.' }
  end

  def failure
    { status: 'error', errors: errors + @record.errors.full_messages }
  end

  def admin_path = "/admin/#{self.class.model.model_name.route_key}/#{@record.id}"

  def changes
    @record.changes.to_h do |field, (before, after)|
      [field, self.class.long_fields.include?(field) ? long_change(before, after) : { from: before, to: after }]
    end
  end

  # Long texts would drown the preview, so summarise instead of echoing them.
  def long_change(before, after)
    { from_length: before.to_s.length, to_length: after.to_s.length,
      new_beginning: after.to_s.truncate(LONG_FIELD_PREVIEW) }
  end

  def warnings
    @warnings ||= [].tap do |list|
      list.concat(model_warnings)
      list << 'It is being published and will become publicly visible.' if publishing?
      list << 'It is being unpublished and will disappear from the site.' if unpublishing?
    end
  end

  # Subclasses add whatever is worth saying about their own fields.
  def model_warnings = []

  def publishing? = @record.changed.include?('published') && @record.published
  def unpublishing? = @record.changed.include?('published') && !@record.published

  def errors = @errors ||= []
end
