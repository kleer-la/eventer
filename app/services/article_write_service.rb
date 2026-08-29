# frozen_string_literal: true

# Creates or edits a blog article on behalf of an MCP client, in two steps:
# a preview that persists nothing, then the actual save once the user confirms.
#
# Permissions mirror the admin screens: `published` is only writable by someone
# who can :set_published (publisher, marketing, administrator), so a `content`
# user can draft and edit from the chat but never publish — the same line
# ability.rb draws for the forms.
class ArticleWriteService
  EDITABLE = %i[title tabtitle description body lang slug cover header industry noindex selected].freeze
  BODY_PREVIEW_LENGTH = 200

  def initialize(ability:, article: nil, category: nil, published: nil, **fields)
    @ability = ability
    @article = article || Article.new
    @category = category
    @published = published
    @fields = fields.slice(*EDITABLE).compact
  end

  def call(confirm: false)
    assign
    return failure if errors.any? || !@article.valid?

    saved_warnings = warnings # computed before saving: afterwards nothing is dirty
    return preview unless confirm

    @article.save!
    { status: 'saved', id: @article.id, slug: @article.slug, title: @article.title,
      published: @article.published, admin_path: "/admin/articles/#{@article.id}",
      warnings: saved_warnings }
  end

  private

  def assign
    @article.assign_attributes(@fields)
    assign_category
    assign_published
  end

  def assign_category
    return if @category.blank?

    category = Category.find_by(name: @category)
    if category.nil?
      return errors << "Unknown category #{@category.inspect}. Existing ones: #{Category.pluck(:name).join(', ')}"
    end

    @article.category = category
  end

  def assign_published
    return if @published.nil? || @published == @article.published

    return errors << 'You are not allowed to change whether an article is published' unless @ability.can?(
      :set_published, Article
    )

    @article.published = @published
  end

  def preview
    { status: 'preview', changes: changes, warnings: warnings,
      note: 'Nothing was saved. Call again with confirm=true to apply these changes.' }
  end

  def failure
    { status: 'error', errors: errors + @article.errors.full_messages }
  end

  def changes
    @article.changes.to_h do |field, (before, after)|
      [field, field == 'body' ? body_change(before, after) : { from: before, to: after }]
    end
  end

  # Bodies are long enough to drown the preview, so summarise instead of echoing.
  def body_change(before, after)
    { from_length: before.to_s.length, to_length: after.to_s.length,
      new_beginning: after.to_s.truncate(BODY_PREVIEW_LENGTH) }
  end

  def warnings
    @warnings ||= [].tap do |list|
      list << 'The body changed: the spoken-audio version will be regenerated.' if @article.changed.include?('body')
      list << 'The article is being published and will become publicly visible.' if publishing?
      list << 'The article is being unpublished and will disappear from the site.' if unpublishing?
    end
  end

  def publishing? = @article.changed.include?('published') && @article.published
  def unpublishing? = @article.changed.include?('published') && !@article.published

  def errors = @errors ||= []
end
