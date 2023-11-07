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
          include: { trainers: { only: [:name, :bio, :bio_en, :gravatar_email, :twitter_username, :linkedin_url] } }
      end
    end
  end

  # GET /articles/1
  def show
    @article = Article.find(params[:id])
    respond_to do |format|
      format.json { render json: @article, 
        methods: [:category_name],
        include: { trainers: { only: [:name, :bio, :bio_en, :gravatar_email, :twitter_username, :linkedin_url] } } }
    end
  end
end
