# frozen_string_literal: true

class Api::NewsController < ApplicationController
  def index
    news = News.visible.order(event_date: :desc)
    respond_to do |format|
      format.json do
        render json: news,
               include: { trainers: { only: %i[name bio bio_en gravatar_email twitter_username
                                               linkedin_url] } }
      end
    end
  end

  def preview
    news = News.all.order(event_date: :desc)
    respond_to do |format|
      format.json do
        render json: news,
               include: { trainers: { only: %i[name bio bio_en gravatar_email twitter_username
                                               linkedin_url] } }
      end
    end
  end
end
