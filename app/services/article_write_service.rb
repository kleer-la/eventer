# frozen_string_literal: true

class ArticleWriteService < ContentWriteService
  self.model = Article
  self.editable_fields = %i[title tabtitle description body lang slug cover header industry noindex selected]
  self.long_fields = %w[body]

  private

  def model_warnings
    return [] unless @record.changed.include?('body')

    ['The body changed: the spoken-audio version will be regenerated.']
  end
end
