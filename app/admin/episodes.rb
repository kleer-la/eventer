# frozen_string_literal: true

ActiveAdmin.register Episode do
  menu parent: 'We Publish'

  permit_params :podcast_id, :season, :episode, :title, :description, :youtube_url, :spotify_url,
                :thumbnail_url, :published_at

  index do
    selectable_column
    id_column
    column :podcast
    column :season
    column :episode
    column :title
    column :published_at
    actions
  end

  filter :podcast
  filter :title
  filter :published_at

  form do |f|
    f.inputs do
      f.input :podcast
      f.input :season
      f.input :episode
      f.input :title
      f.input :description, as: :rich_text_area
      f.input :youtube_url
      f.input :spotify_url
      f.input :thumbnail_url
      f.input :published_at, as: :datepicker
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :podcast
      row :season
      row :episode
      row :title
      row :description do |episode|
        episode.description.to_s.html_safe
      end
      row :youtube_url
      row :spotify_url
      row :thumbnail_url
      row :published_at
      row :created_at
      row :updated_at
    end
  end

  controller do
    def create
      create! do |success, _failure|
        success.html { redirect_to admin_podcast_path(resource.podcast) }
      end
    end
  end
end
