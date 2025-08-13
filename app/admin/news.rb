# frozen_string_literal: true

ActiveAdmin.register News do
  menu parent: 'We Publish'
  permit_params :lang, :title, :where, :description, :url, :img, :video, :audio, :event_date, :visible,
                trainer_ids: []

  controller do
    def show
      @news = scoped_collection.includes(:trainers).find(params[:id])
      show!
    end
  end

  scope :all, default: true
  scope :visible
  scope :hidden, -> { where(visible: false) }

  action_item :view_old_version, only: :index do
    link_to 'Old News View', news_index_path, class: 'button'
  end

  index do
    selectable_column
    id_column
    column :lang
    column :title
    column :where
    column :visible do |news|
      status_tag news.visible ? 'Yes' : 'No',
                 class: news.visible ? 'ok' : 'error'
    end
    column :event_date
    column :created_at
    actions
  end

  filter :lang
  filter :title
  filter :where
  filter :visible
  filter :event_date
  filter :created_at

  form do |f|
    f.inputs do
      f.input :lang, as: :select, collection: News.langs.keys
      f.input :title
      f.input :visible
      f.input :where
      f.input :description
      f.input :url, hint: 'Link to more information or external article'
      f.input :img, hint: 'Image URL to display on the news page'
      f.input :video
      f.input :audio
      f.input :event_date, as: :datepicker
      f.input :trainers, as: :check_boxes, collection: Trainer.sorted
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :lang
      row :title
      row :visible do |news|
        status_tag news.visible ? 'Yes' : 'No',
                   class: news.visible ? 'ok' : 'error'
      end

      row :where
      row :description
      row :url do |news|
        if news.url.present?
          div link_to news.url, news.url, target: '_blank'
          div iframe src: news.url, width: '100%', height: '400px'
        end
      end
      row :img do |news|
        if news.img.present?
          img_url = news.img.start_with?('/') ? "https://www.kleer.la#{news.img}" : news.img
          div link_to img_url, news.img, target: '_blank'
          div image_tag img_url, style: 'max-width: 500px'
        end
      end
      row :video do |news|
        if news.video.present?
          div link_to news.video, news.video, target: '_blank'
          div iframe src: news.video, width: '100%', height: '400px'
        end
      end
      row :audio do |news|
        if news.audio.present?
          div link_to news.audio, news.audio, target: '_blank'
          div audio controls: true do
            source src: news.audio
          end
        end
      end
      row :event_date

      panel 'Trainers' do
        table_for resource.trainers do
          column :name
          column :email
        end
      end

      row :created_at
      row :updated_at
    end
  end
end
