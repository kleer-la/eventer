ActiveAdmin.register Resource do
  menu parent: 'We Publish'

  permit_params :title_es, :title_en, :format, :slug, :landing_es, :landing_en,
                :getit_es, :getit_en, :buyit_es, :buyit_en, :cover_es, :cover_en,
                :description_es, :description_en, :comments_es, :comments_en,
                :share_text_es, :share_text_en, :tags_es, :tags_en,
                :long_description_es, :preview_es,
                :long_description_en, :preview_en,
                category_ids: [], author_ids: [], translator_ids: [], illustrator_ids: [],
                recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy]

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id].strip)
    end
  end

  index do
    selectable_column
    id_column
    column :slug
    column :title_es
    column :title_en
    column :category do |article|
      article.category ? link_to(article.category.name, admin_category_path(article.category)) : 'None'
    end
    column :created_at
    actions
  end

  form do |f|
    f.inputs 'Spanish Details' do
      f.input :title_es
      f.input :format
      f.input :categories, as: :check_boxes, collection: Category.all
      f.input :slug, hint: 'Empty -> automatic from "title es" (slug an id for human readable links)'
      f.input :landing_es
      f.input :getit_es, hint: 'URL para descargar'
      f.input :buyit_es, hint: 'URL para Comprar'
      f.input :cover_es
      f.input :description_es, input_html: { maxlength: 220, rows: 5 }
      f.input :comments_es, input_html: { rows: 2 }
      f.input :long_description_es, input_html: { rows: 7 },
                                    hint: raw("Use <a href='https://www.markdownguide.org/basic-syntax/'>Markdown Cheatsheet</a> for formatting.")
      f.input :preview_es, hint: 'URL para Preview'
      f.input :share_text_es
      f.input :tags_es
    end

    f.inputs 'English Details' do
      f.input :title_en
      f.input :landing_en
      f.input :getit_en, hint: 'URL para descargar'
      f.input :buyit_en, hint: 'URL para Comprar'
      f.input :cover_en
      f.input :description_en, input_html: { rows: 5 }
      f.input :comments_en, input_html: { rows: 2 }
      f.input :long_description_en, input_html: { rows: 7 },
                                    hint: raw("Use <a href='https://www.markdownguide.org/basic-syntax/'>Markdown Cheatsheet</a> for formatting.")
      f.input :preview_en, hint: 'URL para Preview'
      f.input :share_text_en
      f.input :tags_en
    end

    f.inputs 'Associations' do
      f.input :authors, as: :check_boxes, collection: Trainer.sorted
      f.input :translators, as: :check_boxes, collection: Trainer.sorted
      f.input :illustrators, as: :check_boxes, collection: Trainer.sorted
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

  show do
    attributes_table do
      row :title_es
      row :title_en
      row :format
      row :slug
      row :categories
      row :landing_es
      row :landing_en
      row :getit_es
      row :getit_en
      row :buyit_es
      row :buyit_en
      row :cover_es
      row :cover_en
      row :description_es
      row :description_en
      row :comments_es
      row :comments_en
      row :long_description_es
      row :long_description_en
      row :preview_es
      row :preview_en
      row :share_text_es
      row :share_text_en
      row :tags_es
      row :tags_en
      row :authors
      row :translators
      row :illustrators
      row :created_at
      row :updated_at

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
  end
end
