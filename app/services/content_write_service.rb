# frozen_string_literal: true

# Shared machinery for the MCP write tools: assign the given fields, validate,
# return a preview that persists nothing, and only save on confirm.
#
# It also carries the publishing guard. For Article and Resource, `published` is
# the one rule ability.rb expresses outside plain CRUD (`cannot :set_published`),
# so it never travels with the rest of the fields: a content user can draft and
# edit but not publish, the same line the admin forms draw. News and Service are
# published without that guard, and Page, Podcast and Episode have no such flag
# at all — `publication_flag` and `guarded_publication` say which is which.
class ContentWriteService
  # Subclasses declare what they write: the model, the fields a tool may set,
  # which of those are long enough to summarise instead of echoing, which are
  # ActionText (those never reach record.changes), and whether it has a
  # `published` flag at all. class_attribute so a subclass inherits the defaults
  # and overrides only what differs.
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
    # `replacements` travels with the fields but is not one of them: it says how
    # to edit a long field in place instead of giving its new value.
    @replacements = fields[:replacements]
    @fields = fields.slice(*self.class.editable_fields).compact
    @applied = {}
  end

  def call(confirm: false)
    assign
    return failure if errors.any? || !@record.valid?

    saved_warnings = warnings # computed before saving: afterwards nothing is dirty
    return preview unless confirm

    @record.save!
    { status: 'saved', id: @record.id, slug: @record.try(:slug), title: label,
      published: publication_value, admin_path: admin_path, warnings: saved_warnings }
      .compact.merge(saved_extras)
  end

  private

  def assign
    @rich_text_before = self.class.rich_text_fields.to_h { |f| [f.to_s, @record.public_send(f).to_s] }
    apply_replacements
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

  # Find/replace inside long fields, resolved before anything is assigned so a
  # `find` that no longer matches fails the whole call instead of half-editing.
  def apply_replacements
    return if @replacements.blank?

    patch = LongTextPatch.new(@replacements, patchable: self.class.long_field_names, given: @fields.keys,
                                             current: ->(field) { @record.public_send(field) }).apply
    errors.concat(patch.errors)
    @fields.merge!(patch.fields.symbolize_keys)
    @applied = patch.applied
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
    ContentChangePreview.new(@record, fields: @fields, long: self.class.long_field_names,
                                      before: @rich_text_before, applied: @applied).to_h
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

  # What the caller could not have known before saving and needs afterwards —
  # a participant's verification code, generated on create.
  def saved_extras = {}

  def publishing? = publication_changed? && publication_value
  def unpublishing? = publication_changed? && !publication_value

  def publication_changed?
    flag = self.class.publication_flag
    flag.present? && @record.changed.include?(flag.to_s)
  end

  def errors = @errors ||= []
end
