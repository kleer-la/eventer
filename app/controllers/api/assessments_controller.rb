# frozen_string_literal: true

module Api
  class AssessmentsController < ApplicationController
    def show
      assessment = Assessment.find(params[:id])
      render json: {
        id: assessment.id,
        title: assessment.title,
        description: assessment.description,
        question_groups: assessment.question_groups.as_json(
          only: %i[id name description position],
          include: { questions: { only: %i[id name description position question_type],
                                  include: { answers: { only: %i[id text position] } } } }
        ),
        questions: assessment.questions.where(question_group_id: nil).as_json(
          only: %i[id name description position question_type],
          include: { answers: { only: %i[id text position] } }
        ),
        rule_based: assessment.rule_based
      }
    end
  end
end
