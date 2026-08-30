# frozen_string_literal: true

# Shared machinery for the MCP write tools: assign the given fields, validate,
# return a preview that persists nothing, and only save on confirm.
#
# It also carries the publishing guard. For Article and Resource, `published` is
# the one rule ability.rb expresses outside plain CRUD (`cannot :set_published`),
# so it never travels with the rest of the fields: a content user can draft and
# edit but not publish, the same line the admin forms draw. Models that spell it
# `visible`, or have no such flag at all, say so through `publication_flag`.
class ContentWriteService
  LONG_FIELD_PREVIEW = 200

  # Subclasses declare what they write: the model, the fields a tool may set,
  # which of those are long enough to summarise instead of echoing, which are
  # ActionText (those never reach record.changes), and how the model spells
  # "publicly visible" — :published, :visible, or nothing. class_attribute so a
  # subclass inherits the defaults and overrides only what differs.
  class_attribute :model, :editable_fields, :publication_flag, :guarded_publication,
                  :long_fields, :rich_text_fields

  self.long_fields = []
  self.rich_text_fields = []
  self.publication_flag = :published
  self.guarded_publication = true

  def self.long_field_names = (long_fields + rich_text_fields).map(&:to_s)

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
    { status: 'saved', id: @record.id, slug: @record.try(:slug), title: label,
      published: publication_value, admin_path: admin_path, warnings: saved_warnings }.compact
  end

  private

  def assign
    @rich_text_before = self.class.rich_text_fields.to_h { |f| [f.to_s, @record.public_send(f).to_s] }
    @record.assign_attributes(@fields)
    assign_category
    assign_published
  rescue ArgumentError => e
    # An enum (Resource#format, Page#template) rejecting a value it does not know
    errors << e.message
  end

  def assign_category
    return if @category.blank?

    category = Category.find_by(name: @category)
    if category.nil?
      return errors << "Unknown category #{@category.inspect}. Existing ones: #{Category.pluck(:name).join(', ')}"
    end

    @record.category = category
  end

  def assign_published
    flag = self.class.publication_flag
    return if @published.nil? || flag.nil? || @published == @record.public_send(flag)

    if self.class.guarded_publication && !@ability.can?(:set_published, self.class.model)
      return errors << 'You are not allowed to change whether this is published'
    end

    @record.public_send("#{flag}=", @published)
  end

  def publication_value
    flag = self.class.publication_flag
    flag && @record.public_send(flag)
  end

  # Article and News answer to title, Service and Page to name.
  def label = @record.try(:title) || @record.try(:name)

  def preview
    { status: 'preview', changes: changes, warnings: warnings,
      note: 'Nothing was saved. Call again with confirm=true to apply these changes.' }
  end

  def failure
    { status: 'error', errors: errors + @record.errors.full_messages }
  end

  def admin_path = "/admin/#{self.class.model.model_name.route_key}/#{@record.id}"

  def changes
    attribute_changes.merge(rich_text_changes)
  end

  def attribute_changes
    @record.changes.to_h do |field, (before, after)|
      [field, self.class.long_field_names.include?(field) ? long_change(before, after) : { from: before, to: after }]
    end
  end

  # ActionText lives in its own table, so a change to it never shows up in
  # record.changes; report it from what the caller actually passed.
  def rich_text_changes
    self.class.rich_text_fields.select { |field| @fields.key?(field) }.to_h do |field|
      [field.to_s, long_change(@rich_text_before[field.to_s], @fields[field])]
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

  def publishing? = publication_changed? && publication_value
  def unpublishing? = publication_changed? && !publication_value

  def publication_changed?
    flag = self.class.publication_flag
    flag.present? && @record.changed.include?(flag.to_s)
  end

  def errors = @errors ||= []
end
