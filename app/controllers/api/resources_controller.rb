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
      Resource.includes(:authors, :translators, :illustrators, :assessments, :concepts)
    end

    # The site's sitemap needs one URL per concept, so concepts resources carry
    # their slugs here; the cards themselves come from show.
    def index_json(resources)
      resources.map do |resource|
        json = resource.as_json(
          methods: %i[category_name],
          include: {
            authors: { only: trainer_index_fields },
            translators: { only: trainer_index_fields },
            illustrators: { only: trainer_index_fields }
          }
        )
        next json unless resource.concepts?

        json.merge('concepts' => resource.concepts.map { |c| c.as_json(only: %i[slug lang updated_at]) })
      end
    end

    public

    def index
      render json: index_json(resources_with_associations.where(published: true).order(created_at: :desc))
    end

    def preview
      render json: index_json(resources_with_associations.order(created_at: :desc))
    end

    def show
      lang = params[:lang] || 'es'
      return render json: { error: 'Invalid language' }, status: :bad_request unless %w[es en].include?(lang)

      # Any slug finds it — Spanish, English or an old one — and `slug` answers
      # the one of the language asked for; the site redirects when they differ.
      resource = resources_with_associations.find_by_any_slug(params[:id].downcase)

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

      resource_json['slug'] = resource.slug_for(lang)
      resource_json['concepts'] = resource.concepts.where(lang:).map(&:as_api_json) if resource.concepts?

      render json: resource_json.merge(
        recommended: resource.recommended(lang:)
      )
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Resource not found' }, status: :not_found
    end
  end
end
