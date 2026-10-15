# frozen_string_literal: true

class ArticleWriteService < ContentWriteService
  include TrainerAssignment

  self.model = Article
  self.editable_fields = %i[title tabtitle description body lang slug cover header industry noindex selected
                            redirect_url substantive_change_at]
  self.long_fields = %w[body]

  # Rails would cast an unparseable string to nil and silently clear the
  # field, so the moment is parsed here and a bad one fails the call.
  def initialize(**args)
    super
    parse_substantive_change_at
  end

  private

  def parse_substantive_change_at
    value = @fields[:substantive_change_at]
    return if value.nil?

    @fields[:substantive_change_at] = value == 'now' ? Time.current : Time.iso8601(value.to_s)
  rescue ArgumentError
    @fields.delete(:substantive_change_at)
    errors << "substantive_change_at must be an ISO 8601 date-time (2026-10-01T12:00:00Z) or 'now'"
  end

  def model_warnings
    return [] unless @record.changed.include?('body')

    ['The body changed: the spoken-audio version will be regenerated.']
  end

  # With redirect_url the site answers the article's URL with a 301 whether it
  # is published or not (kleer-la/eventer#212, #214).
  def unpublishing_warning
    return super if @record.redirect_url.blank?

    "It is being unpublished: it leaves the blog listing, and its URL answers with a 301 to #{@record.redirect_url}."
  end
end
