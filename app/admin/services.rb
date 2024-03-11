ActiveAdmin.register Service do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params %i[created_at id name service_area_id subtitle updated_at value_proposition outcomes program target faq]
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :card_description, :subtitle, :service_area_id]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

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

  form do |f|
    selected_service_area_id = params[:service_area_id] || f.object.service_area_id

    f.inputs do
      f.input :service_area, as: :select, collection: ServiceArea.all.map{ |sa| [sa.name, sa.id] }, selected: selected_service_area_id
      f.input :name
      f.input :subtitle, as: :rich_text_area
      f.input :value_proposition, as: :rich_text_area
      f.input :outcomes, as: :rich_text_area, hint: 'Bullet list'
      f.input :program, as: :rich_text_area, hint: 'Numered list with one bullet element'
      f.input :target, as: :rich_text_area
      f.input :faq, as: :rich_text_area
    end
    f.actions
  end

  show do
    attributes_table do
      row :service_area if service.service_area # Optional: Show ServiceArea if relevant
      row :name
      row :subtitle
      row :value_proposition do |service| 
        service.value_proposition.to_s.html_safe if service.value_proposition.present?
      end

      panel "Outcomes List" do
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

      panel "Program" do
        service.program_list.each_with_index do |(main_item, collapsible_item), index|
          div class: "program-row" do
            span main_item, class: "main-item"
            span "(expand)", class: "toggle-collapsible", style: "cursor: pointer;", "data-target": "collapsible-#{index}"
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
                    this.textContent = "(collapse)";
                  } else {
                    target.style.display = "none";
                    this.textContent = "(expand)";
                  }
                });
              });
            });
          JS
        end
      end
    end
  end
end
