# frozen_string_literal: true

class Api::ArticlesController < ApplicationController
  # GET /articles
  def index
    @articles = Article.order(selected: :desc, created_at: :desc)
    respond_to do |format|
      format.json do
        render json: @articles.order(created_at: :desc),
               except: [:body],
               methods: %i[abstract category_name],
               include: { trainers: { only: %i[name bio bio_en gravatar_email twitter_username
                                               linkedin_url] } }
      end
    end
  end

  # GET /articles/1
  def show
    @article = Article.friendly.find(params[:id].downcase)
    respond_to do |format|
      format.json do
        render json: @article,
               methods: %i[category_name recommended],
               include: { trainers: { only: %i[name bio bio_en gravatar_email twitter_username
                                               linkedin_url] } }
      end
    end
  end
end
