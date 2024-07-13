ActiveAdmin.register Podcast do
  menu parent: 'Podcast Mgnt'

  permit_params :title, :description, :youtube_url, :spotify_url, :thumbnail_url,
                episodes_attributes: %i[id season episode title description youtube_url spotify_url thumbnail_url published_at _destroy]

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

    f.inputs do
      f.has_many :episodes, allow_destroy: true, new_record: true do |e|
        e.input :season
        e.input :episode
        e.input :title
        e.input :description, as: :rich_text_area
        e.input :youtube_url
        e.input :spotify_url
        e.input :thumbnail_url
        e.input :published_at, as: :datepicker
      end
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
