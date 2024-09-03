# frozen_string_literal: true

ActiveAdmin.register Article do
  menu parent: 'We Publish'

  permit_params :lang, :published, :selected, :category_id, :title, :tabtitle, :description, :slug, :cover, :body,
                trainer_ids: [], recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy]

  FriendlyId::Slug.class_eval do
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at id id_value scope slug sluggable_id sluggable_type]
    end
  end

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id].strip)
    end
  end

  index do
    selectable_column
    id_column
    column :title
    column :lang
    column :published
    column :selected
    column :category do |article|
      article.category ? link_to(article.category.name, admin_category_path(article.category)) : 'None'
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :tabtitle
      row :description
      row :lang
      row :published
      row :selected
      row :category do |article|
        article.category ? link_to(article.category.name, admin_category_path(article.category)) : 'None'
      end
      row :slug
      row :cover
      row :body
      row :created_at
      row :updated_at
    end

    panel 'Trainers' do
      table_for resource.trainers do
        column :name
        column :email
      end
    end

    panel 'Recommended Content' do
      table_for resource.recommended do
        column :relevance_order do |recommendation|
          recommendation['relevance_order']
        end
        column :title do |recommendation|
          recommendation['title']
        end
        column :type do |recommendation|
          recommendation['type']
        end
        column :subtitle do |recommendation|
          recommendation['subtitle']
        end
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :lang, as: :radio
      f.input :published
      f.input :selected
      f.input :category, as: :select, collection: Category.sorted
      f.input :title
      f.input :tabtitle
      f.input :description
      f.input :slug
      f.input :cover
      f.input :body, input_html: { rows: 20 }
      f.input :trainers, as: :check_boxes, collection: Trainer.sorted
    end
    f.inputs 'Recommended Contents' do
      f.has_many :recommended_contents, allow_destroy: true, new_record: true do |rc|
        rc.input :target_type, as: :select,
                               collection: %w[Article EventType Service Resource],
                               input_html: { class: 'target-type-select' }
        rc.input :target_id, label: 'Target', as: :select,
                             collection: [],
                             input_html: { class: 'target-id-select' }
        rc.input :relevance_order
        rc.input :current_target_info, as: :hidden,
                                       input_html: {
                                         class: 'current-target-info',
                                         value: { type: rc.object.target_type, id: rc.object.target_id }.to_json
                                       }
      end
    end
    f.actions
    script do
      raw RecommendableHelper.recommended_content_js(Article)
    end
  end
end
