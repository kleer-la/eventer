module Api
  class ResourcesController < ApplicationController
    private

    def trainer_index_fields
      %i[name landing]
    end

    def trainer_show_fields
      %i[name bio gravatar_email twitter_username linkedin_url bio_en]
    end

    public

    def index
      render(
        json: Resource.order(created_at: :desc),
        methods: %i[category_name],
        include: {
          authors: { only: trainer_index_fields },
          translators: { only: trainer_index_fields },
          illustrators: { only: trainer_index_fields }
        }
      )
    end

    def show
      resource = Resource.friendly.find(params[:id].downcase)
      render(
        json: resource,
        methods: %i[category_name],
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
