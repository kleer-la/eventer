# frozen_string_literal: true

class ArticlesController < ApplicationController
  before_action :set_article, only: %i[show edit update destroy]

  # GET /articles
  def index
    @articles = Article.order(selected: :desc, created_at: :desc)
  end

  # GET /articles/1
  def show; end

  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit; end

  # POST /articles
  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to edit_article_path(@article), notice: 'Article was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /articles/1
  def update
    if @article.update(article_params)
      redirect_to edit_article_path(@article), notice: 'Article was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /articles/1
  def destroy
    @article.destroy
    redirect_to articles_url, notice: 'Article was successfully destroyed.'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_article
    @article = Article.friendly.find(params[:id].downcase)
  end

  # Only allow a trusted parameter "white list" through.
  def article_params
    params[:article][:slug] = params[:article][:slug].downcase if params[:article][:slug].present?
    params.require(:article)
          .permit(:title, :slug, :body, :lang, :description, :published, :tabtitle, :cover, :selected, :category_id, trainer_ids: [])
  end
end
