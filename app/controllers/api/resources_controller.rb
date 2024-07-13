# frozen_string_literal: true

module Api
  class ResourcesController < ApplicationController
    # GET /api/service_areas
    def index
      render(
        json: Resource.order(created_at: :desc),
        methods: %i[category_name],
        include: {
          authors: { only: %i[name landing] },
          translators: { only: %i[name landing] },
          illustrators: { only: %i[name landing] }
        }
      )
    end
  end
end
