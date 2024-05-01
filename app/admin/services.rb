ActiveAdmin.register Service do
  menu parent: 'Services Mgnt'

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params %i[created_at id name slug service_area_id subtitle updated_at value_proposition
                  outcomes program target faq definitions pricing brochure]

  # or
  #
  # permit_params do
  #   permitted = [:name, :card_description, :subtitle, :service_area_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  controller do
    def find_resource
      scoped_collection.friendly.find(params[:id])
    end
  end

  index do
    selectable_column
    id_column
    column :name
    column :subtitle
    column :service_area if defined?(ServiceArea) # Optional: Display associated ServiceArea if relevant
    actions
  end

  filter :name
  filter :subtitle
  filter :service_area if defined?(ServiceArea) # Optional: Filter by ServiceArea if relevant

  hint_colapsable = 'Copy this in a empty line to add an item:<ol><li>item title<ul><li>item content</li></ul></li></ol>'.html_safe
  form do |f|
    selected_service_area_id = params[:service_area_id] || f.object.service_area_id

    f.inputs do
      f.input :service_area, as: :select, collection: ServiceArea.all.map{ |sa| [sa.name, sa.id] }, selected: selected_service_area_id
      f.input :name
      f.input :slug, hint: 'The URL-friendly version of the name. (Empty to auto generete)'
      f.input :subtitle, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
      f.input :outcomes, as: :rich_text_area, hint: 'Bullet list'
      f.input :definitions, as: :rich_text_area
      f.input :program, as: :rich_text_area, hint: hint_colapsable
      f.input :target, as: :rich_text_area
      f.input :pricing
      f.input :faq, as: :rich_text_area, hint: hint_colapsable
      f.input :brochure
    end
    f.actions
  end

  show do
    attributes_table do
      row :service_area if service.service_area # Optional: Show ServiceArea if relevant
      row :name
      row :slug
      row :subtitle
      row :pricing
      row :value_proposition do |service| 
        service.value_proposition.to_s.html_safe if service.value_proposition.present?
      end
      row :definitions do |service| 
        service.definitions.to_s.html_safe if service.definitions.present?
      end

      panel 'Outcomes List' do
        div class: "outcomes-list" do
          ul style: "column-count: 2;" do
            service.outcomes_list&.each do |item|
              li(style: "list-style-type: none;") do
                span class: "custom-bullet" do
                  # Your custom bullet, e.g., a check mark icon
                end
                div raw(item), class: "list-content"
              end
            end
          end
        end
      end

      panel 'Program' do
        service.program_list.each_with_index do |(main_item, collapsible_item), index|
          div class: "program-row" do
            span main_item, class: "main-item"
            span '(+)', class: "toggle-collapsible", style: "cursor: pointer;", "data-target": "collapsible-#{index}"
            span collapsible_item, id: "collapsible-#{index}", class: "collapsible-content", style: "display: none;"
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
          div class: "program-row" do
            span main_item, class: "main-item"
            span "(expand)", class: "toggle-collapsible", style: "cursor: pointer;", "data-target": "collapsible-#{100+index}"
            span collapsible_item, id: "collapsible-#{100+index}", class: "collapsible-content", style: "display: none;"
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
    end
  end
end
