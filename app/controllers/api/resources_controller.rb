module Api
  class ResourcesController < ApplicationController
    private

    def trainer_index_fields
      %i[name landing]
    end

    def trainer_show_fields
      %i[name bio gravatar_email twitter_username linkedin_url bio_en landing]
    end

    def resources_with_associations
      Resource.includes(:authors, :translators, :illustrators, :assessments)
    end

    public

    def index
      resources = resources_with_associations.where(published: true).order(created_at: :desc)
      render(
        json: resources,
        methods: %i[category_name],
        include: {
          authors: { only: trainer_index_fields },
          translators: { only: trainer_index_fields },
          illustrators: { only: trainer_index_fields }
        }
      )
    end

    def preview
      resources = resources_with_associations.order(created_at: :desc)
      render(
        json: resources,
        methods: %i[category_name],
        include: {
          authors: { only: trainer_index_fields },
          translators: { only: trainer_index_fields },
          illustrators: { only: trainer_index_fields }
        }
      )
    end

    def show
      lang = params[:lang] || 'es'
      return render json: { error: 'Invalid language' }, status: :bad_request unless %w[es en].include?(lang)

      resource = resources_with_associations.friendly.find(params[:id].downcase)

      # Find the assessment for the correct language
      assessment_data = resource.assessments.find_by(language: lang)

      resource_json = resource.as_json(
        methods: %i[category_name downloadable],
        include: {
          authors: { only: trainer_show_fields },
          translators: { only: trainer_show_fields },
          illustrators: { only: trainer_show_fields }
        }
      )

      # Add the localized assessment data if it exists
      if assessment_data
        resource_json['assessment'] = {
          id: assessment_data.id,
          title: assessment_data.title,
          description: assessment_data.description,
          rule_based: assessment_data.rule_based,
          language: assessment_data.language
        }
      end

      render json: resource_json.merge(
        recommended: resource.recommended(lang:)
      )
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Resource not found' }, status: :not_found
    end
  end
end
