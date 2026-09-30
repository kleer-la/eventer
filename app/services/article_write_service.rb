# frozen_string_literal: true

class ArticleWriteService < ContentWriteService
  include TrainerAssignment

  self.model = Article
  self.editable_fields = %i[title tabtitle description body lang slug cover header industry noindex selected
                            redirect_url]
  self.long_fields = %w[body]

  private

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
