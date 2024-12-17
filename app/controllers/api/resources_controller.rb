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
      Resource.includes(:authors, :translators, :illustrators)
    end

    public

    def index
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
      resource = resources_with_associations.friendly.find(params[:id].downcase)
      render(
        json: resource,
        methods: %i[category_name recommended],
        include: {
          authors: { only: trainer_show_fields },
          translators: { only: trainer_show_fields },
          illustrators: { only: trainer_show_fields }
        }
      )
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Resource not found' }, status: :not_found
    end
  end
end
