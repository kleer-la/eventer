# frozen_string_literal: true

ActiveAdmin.register Podcast do
  menu parent: 'We Publish'

  permit_params :title, :description, :youtube_url, :spotify_url, :thumbnail_url

  controller do
    def show
      @podcast = scoped_collection.includes(:episodes).find(params[:id])
      show!
    end
  end

  index do
    selectable_column
    id_column
    column :title
    column :youtube_url
    column :spotify_url
    column :created_at
    actions
  end

  filter :title
  filter :created_at

  form do |f|
    f.inputs do
      f.input :title
      f.input :description, as: :rich_text_area
      f.input :youtube_url
      f.input :spotify_url
      f.input :thumbnail_url
    end

    f.actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :description do |podcast|
        podcast.description.to_s.html_safe
      end
      row :youtube_url
      row :spotify_url
      row :thumbnail_url
      row :created_at
      row :updated_at
    end
    panel 'Episodes' do
      table_for podcast.episodes do
        column :season
        column :episode
        column :title
        column :published_at
        column :actions do |episode|
          link_to 'View', admin_episode_path(episode)
        end
      end
    end
    panel 'Add New Episode' do
      render partial: 'admin/episodes/form', locals: { podcast: }
    end
  end
end
