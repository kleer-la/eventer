# frozen_string_literal: true

ActiveAdmin.register Article do
  menu parent: 'We Publish'

  permit_params :lang, :published, :selected, :category_id, :title, :tabtitle, :description, :slug, :cover, :body,
                :industry, :noindex,
                trainer_ids: [], recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy]

  scope :all
  scope :published, default: true
  scope :unpublished

  FriendlyId::Slug.class_eval do
    def self.ransackable_attributes(_auth_object = nil)
      %w[created_at id id_value scope slug sluggable_id sluggable_type]
    end
  end

  filter :title
  filter :slug
  filter :industry, as: :select, collection: Article.industries
  filter :body

  action_item :view_old_version, only: :index do
    link_to 'Old version', articles_path, class: 'button'
  end

  controller do
    def scoped_collection
      super.includes(:category, :trainers)
    end

    def find_resource
      scoped_collection.friendly.find(params[:id].strip)
    end

    def destroy
      article = resource
      if article.published?
        flash[:error] = "Can't delete a published article"
        redirect_to admin_article_path(article)
      else
        super
      end
    end
  end

  index do
    selectable_column
    id_column
    column :title
    column :lang
    column :published
    column :selected
    column :industry
    column :category do |article|
      article.category ? link_to(article.category.name, admin_category_path(article.category)) : 'None'
    end
    column :created_at

    actions defaults: false do |article|
      item 'View', admin_article_path(article)
      text_node '&nbsp;&nbsp;'.html_safe
      item 'Edit', edit_admin_article_path(article)
      text_node '&nbsp;&nbsp;'.html_safe
      if article.published?
        item 'Delete', '#',
             onClick: "alert('Can\\'t delete a published article'); return(false);"
      else
        item 'Delete', admin_article_path(article),
             method: :delete,
             data: { confirm: 'Are you sure you want to delete this?' }
      end
    end
  end
  action_item :preview, only: :show do
    link_to 'Preview', "https://www.kleer.la/es/blog-preview/#{resource.slug}", 
      class: 'button', 
      target: '_blank'
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
      row :noindex
      row :industry
      row :category do |article|
        article.category ? link_to(article.category.name, admin_category_path(article.category)) : 'None'
      end
      row :slug
      row :cover
      row :body do
        markdown resource.body
      end

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
      f.input :noindex
      f.input :industry, as: :select, hint: 'Tiene industria solo si es un caso de estudio', collection: Article.industries.keys.map { |industry|
        [industry.titleize, industry]
      }
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
