# frozen_string_literal: true

ActiveAdmin.register Episode do
  menu parent: 'We Publish'

  permit_params :podcast_id, :season, :episode, :title, :description, :youtube_url, :spotify_url,
                :thumbnail_url, :released_at, :published

  controller do
    def scoped_collection
      super.includes(:podcast)
    end
  end

  index do
    selectable_column
    id_column
    column :podcast
    column :season
    column :episode
    column :title
    column :released_at
    column :published
    actions
  end

  filter :podcast
  filter :title
  filter :released_at
  filter :published

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
      f.input :released_at, as: :datepicker
      f.input :published
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
      row :released_at
      row :published
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
