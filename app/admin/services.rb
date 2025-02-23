# frozen_string_literal: true

ActiveAdmin.register Service do
  menu parent: 'Services Mgnt'

  permit_params %i[created_at id name slug service_area_id subtitle updated_at value_proposition
                   outcomes program target faq definitions pricing brochure side_image ordering visible],
                recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy]

  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id].strip)
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :subtitle
    column :ordering
    column :service_area if defined?(ServiceArea) # Optional: Display associated ServiceArea if relevant
    column :visible do |service|
      status_tag service.visible
    end

    actions
  end

  filter :name
  filter :subtitle
  filter :service_area if defined?(ServiceArea) # Optional: Filter by ServiceArea if relevant

  hint_colapsable = 'Copy this in a empty line to add an item:<ol><li>item title<ul><li>item content</li></ul></li></ol>'.html_safe
  form do |f|
    selected_service_area_id = params[:service_area_id] || f.object.service_area_id

    f.inputs do
      f.input :service_area, as: :select, collection: ServiceArea.all.map { |sa|
                                                        [sa.name, sa.id]
                                                      }, selected: selected_service_area_id
      f.input :name
      f.input :slug, hint: 'The URL-friendly version of the name. (Empty to auto generete)'
      f.input :ordering
      f.input :visible
      f.input :subtitle, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
      f.input :outcomes, as: :rich_text_area, hint: 'Bullet list'
      f.input :definitions, as: :rich_text_area
      f.input :program, as: :rich_text_area, hint: hint_colapsable
      f.input :target, as: :rich_text_area
      f.input :side_image, as: :url
      f.input :pricing
      f.input :faq, as: :rich_text_area, hint: hint_colapsable
      f.input :brochure
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
    end
    f.actions
    script do
      raw RecommendableHelper.recommended_content_js(Page)
    end
  end

  show do
    attributes_table do
      row :service_area if service.service_area # Optional: Show ServiceArea if relevant
      row :name
      row :slug
      row :ordering
      row :visible
      row :subtitle
      row :side_image
      row :pricing
      row :value_proposition do |service|
        service.value_proposition.to_s.html_safe if service.value_proposition.present?
      end
      row :definitions do |service|
        service.definitions.to_s.html_safe if service.definitions.present?
      end
      if service.side_image.present?
        div 'Side Image '
        div do
          image_tag service.side_image
        end
      end

      panel 'Outcomes List' do
        div class: 'outcomes-list' do
          ul style: 'column-count: 2;' do
            service.outcomes_list&.each do |item|
              li(style: 'list-style-type: none;') do
                span class: 'custom-bullet' do
                  # Your custom bullet, e.g., a check mark icon
                end
                div raw(item), class: 'list-content'
              end
            end
          end
        end
      end

      panel 'Program' do
        service.program_list.each_with_index do |(main_item, collapsible_item), index|
          div class: 'program-row' do
            span main_item, class: 'main-item'
            span '(+)', class: 'toggle-collapsible', style: 'cursor: pointer;', "data-target": "collapsible-#{index}"
            span collapsible_item, id: "collapsible-#{index}", class: 'collapsible-content', style: 'display: none;'
          end
        end
        script do
          raw <<-JS.strip_heredoc
            document.addEventListener("DOMContentLoaded", function() {
              document.querySelectorAll('.toggle-collapsible').forEach(function(toggle) {
                toggle.addEventListener('click', function() {
                  var targetId = this.getAttribute('data-target');
                  var target = document.getElementById(targetId);
                  if (target.style.display === "none") {
                    target.style.display = "block";
                    this.textContent = "(-)";
                  } else {
                    target.style.display = "none";
                    this.textContent = "(+)";
                  }
                });
              });
            });
          JS
        end
      end

      if service.pricing.present?
        panel 'Pricing' do
          div do
            image_tag service.pricing
          end
        end
      end

      panel 'FAQ' do
        service.faq_list.each_with_index do |(main_item, collapsible_item), index|
          div class: 'program-row' do
            span main_item, class: 'main-item'
            span '(expand)', class: 'toggle-collapsible', style: 'cursor: pointer;',
                             "data-target": "collapsible-#{100 + index}"
            span collapsible_item, id: "collapsible-#{100 + index}", class: 'collapsible-content',
                                   style: 'display: none;'
          end
        end
      end

      row :brochure do |service|
        link_to service.brochure, service.brochure, target: '_blank' if service.brochure.present?
      end
      panel 'Brochure preview' do
        if service.brochure.present?
          iframe src: service.brochure, width: '100%', height: '500px', frameborder: '0'
          div do
            link_to 'Open PDF in new tab', service.brochure, target: '_blank', rel: 'noopener noreferrer'
          end
        else
          'No PDF available'
        end
      end
      panel 'Recommended Content' do
        table_for resource.recommended do
          column :level do |recommendation|
            recommendation['level']
          end
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
