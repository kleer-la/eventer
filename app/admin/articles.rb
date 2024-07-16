# frozen_string_literal: true

ActiveAdmin.register Article do
  permit_params :lang, :published, :selected, :category, :title, :tabtitle, :description, :slug, :cover, :body,
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
    column :category
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
      row :category
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
        column :title do |recommendation|
          recommendation['title']
        end
        column :type do |recommendation|
          recommendation['type']
        end
        column :description do |recommendation|
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
      f.input :category
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
                               collection: %w[Article EventType Service],
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

    targets = {
      'Article' => Article.all.order(:title).pluck(:title, :id),
      'EventType' => EventType.all.order(:name).pluck(:name, :id),
      'Service' => Service.all.order(:name).pluck(:name, :id)
    }
    script do
      raw <<~JS
        $(document).ready(function() {
          window.targetOptions = #{targets.to_json};

          function updateTargetSelect($targetTypeSelect) {
            var $container = $targetTypeSelect.closest('.has_many_fields');
            var $targetIdSelect = $container.find(".target-id-select");
            var $currentTargetInfo = $container.find(".current-target-info");
            var selectedType = $targetTypeSelect.val();

            var currentTargetInfo;
            try {
              currentTargetInfo = JSON.parse($currentTargetInfo.val() || '{}');
            } catch (e) {
              console.error("Error parsing current target info:", e);
              currentTargetInfo = {};
            }
            var currentTargetType = currentTargetInfo.type;
            var currentTargetId = currentTargetInfo.id;

            $targetIdSelect.empty();
            if (window.targetOptions[selectedType]) {
              $.each(window.targetOptions[selectedType], function(index, item) {
                var option = $('<option></option>').attr('value', item[1]).text(item[0]);
                if (selectedType === currentTargetType && item[1] == currentTargetId) {
                  option.prop('selected', true);
                }
                $targetIdSelect.append(option);
              });
            }
            $targetIdSelect.trigger('change');
          }

          $(document).on('change', ".target-type-select", function() {
            updateTargetSelect($(this));
          });

          // Initialize existing fields
          $(".target-type-select").each(function() {
            updateTargetSelect($(this));
          });

          // Handle dynamically added fields
          $(document).on('has_many_add:after', function() {
            var $newTargetTypeSelect = $(".target-type-select").last();
            updateTargetSelect($newTargetTypeSelect);
          });
        });
      JS
    end
  end
end
