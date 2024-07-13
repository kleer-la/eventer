# frozen_string_literal: true

class NewsController < ApplicationController
  # GET /news
  def index
    @news = News.order(event_date: :desc)
    respond_to do |format|
      format.html
      format.json do
        render json: @news.order(event_date: :desc),
               methods: %i[abstract category_name],
               include: { trainers: { only: %i[name bio bio_en gravatar_email twitter_username
                                               linkedin_url] } }
      end
    end
  end

  # GET /news/1
  def show
    respond_to do |format|
      format.html
      format.json do
        render json: @news,
               methods: [:category_name],
               include: { trainers: { only: %i[name bio bio_en gravatar_email
                                               twitter_username linkedin_url] } }
      end
    end
  end

  # GET /news/new
  def new
    @news = News.new
  end

  # GET /news/1/edit
  def edit
    @news = News.find(params[:id])
  end

  # POST /news
  def create
    @news = News.new(news_params)

    if @news.save
      redirect_to edit_news_path(@news), notice: 'News was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /news/1
  def update
    @news = News.find(params[:id])
    if @news.update(news_params)
      redirect_to edit_news_path(@news), notice: 'News was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /news/1
  def destroy
    news = News.find(params[:id])
    title = news.title
    news.destroy
    redirect_to news_index_path, notice: "News was successfully destroyed. Title: #{title}"
  end

  private

  # Only allow a trusted parameter "white list" through.
  def news_params
    params[:news][:slug] = params[:news][:slug].downcase if params[:news][:slug].present?
    params.require(:news)
          .permit(:title, :where, :lang, :description, :url, :img, :video, :audio, :event_date, trainer_ids: [])
  end
end
