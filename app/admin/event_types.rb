# frozen_string_literal: true

ActiveAdmin.register EventType do
  menu parent: 'Courses Mgnt'

  # You might want to permit these parameters in a controller action
  permit_params :name, :duration, :include_in_catalog, :lang, :platform, :external_id, :tag_name,
                :is_kleer_certification, :csd_eligible, :cover, :side_image, :kleer_cert_seal_image,
                :subtitle, :elevator_pitch, :description, :recipients, :program, :learnings,
                :takeaways, :faq, :materials, :cancellation_policy, :brochure, :external_site_url,
                :extra_script, :canonical_id, :deleted, :noindex, :new_version,
                trainer_ids: [], category_ids: [],
                recommended_contents_attributes: %i[id target_type target_id relevance_order _destroy]

  filter :name
  filter :platform, as: :select
  filter :lang, as: :select
  filter :duration
  filter :deleted
  filter :noindex
  filter :canonical
  filter :kleer_cert_seal_image_present, as: :boolean # , label: 'Cert Image is Empty'
  filter :kleer_cert_seal_image_blank, as: :boolean # , label: 'Cert Image is Not Empty'
  filter :kleer_cert_seal_image

  scope :all, default: false
  scope 'Catalog', :included_in_catalog, default: true

  action_item :view_old_version, only: :index do
    link_to 'Old version', event_types_path, class: 'button'
  end

  config.sort_order = 'name_asc'
  index do
    column :name
    column :platform
    column :lang
    column :duration
    column :behavior do |event_type|
      if event_type.behavior.include?('canonical')
        link_to event_type.behavior, edit_admin_event_type_path(event_type.canonical)
      elsif event_type.behavior == 'redirect to url'
        link_to event_type.behavior, event_type.external_site_url, target: '_blank'
      else
        event_type.behavior
      end
    end
    column :deleted
    actions do |event_type|
      span class: 'table_actions' do
        dropdown_menu '...' do
          item 'Preview', certificate_preview_event_type_path(event_type), title: 'Certificate Preview'
          item 'Events', "/event_types/#{event_type.id}/events", title: 'Event list'
          item 'Testimonies', "/event_types/#{event_type.id}/testimonies", title: 'Testimonies'
          item 'Participants', participants_event_type_path(event_type), title: 'Participants'
        end
      end
    end
  end

  show do
    attributes_table do
      row :name
      row :duration
      row :trainers do |event_type|
        event_type.trainers.map(&:name).join(', ')
      end
      row :categories do |event_type|
        event_type.categories.map(&:name).join(', ')
      end
      row :include_in_catalog
      row :lang
      row :platform
      row :external_id
      row :tag_name
      row :is_kleer_certification
      row :csd_eligible
      row :cover
      row :side_image
      row :kleer_cert_seal_image
      row :subtitle
      row :elevator_pitch
      row :description do |event_type|
        simple_format event_type.description
      end
      row :recipients do |event_type|
        simple_format event_type.recipients
      end
      row :program do |event_type|
        simple_format event_type.program
      end
      row :learnings do |event_type|
        simple_format event_type.learnings
      end
      row :takeaways do |event_type|
        simple_format event_type.takeaways
      end
      row :faq do |event_type|
        simple_format event_type.faq
      end
      row :materials do |event_type|
        simple_format event_type.materials
      end
      row :cancellation_policy do |event_type|
        simple_format event_type.cancellation_policy
      end
      row :brochure do |event_type|
        link_to event_type.brochure, event_type.brochure, target: '_blank' if event_type.brochure.present?
      end
      row :external_site_url do |event_type|
        if event_type.external_site_url.present?
          link_to event_type.external_site_url, event_type.external_site_url,
                  target: '_blank'
        end
      end
      row :extra_script
      row :canonical do |event_type|
        event_type.canonical.unique_name if event_type.canonical.present?
      end
      row :deleted
      row :noindex
      row :new_version
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

  form do |f|
    bkgd_imgs = FileStoreService.current.background_list
    f.inputs 'Event Type Details' do
      f.input :name # , label: I18n.t('formtastic.labels.event_type.name')
      f.input :duration # , label: I18n.t('formtastic.labels.event_type.duration')
      f.input :trainers, as: :check_boxes, collection: Trainer.all
      f.input :categories, as: :check_boxes, collection: Category.all
      f.input :include_in_catalog
      f.input :lang, as: :radio
      f.input :platform, as: :radio
      f.input :external_id, label: 'Academia ID'
      f.input :tag_name, hint: 'Example: "PASOL" will generate project code "PASOL221218"'
      f.input :is_kleer_certification
      f.input :csd_eligible
      f.input :cover
      f.input :side_image
      f.input :kleer_cert_seal_image, as: :select, collection: bkgd_imgs,
                                      input_html: { data: { allow_clear: true, placeholder: 'Select an image' } }
      f.input :subtitle
      f.input :elevator_pitch, as: :text, input_html: { rows: 4, maxlength: 160 },
                               hint: 'No more than 160 characters. Plain text, no HTML or Markdown.'
      f.input :description, as: :text, input_html: { rows: 8 }
      f.input :recipients, as: :text, input_html: { rows: 8 }
      f.input :program, as: :text, input_html: { rows: 8 }
      f.input :learnings, as: :text, input_html: { rows: 8 }
      f.input :takeaways, as: :text, input_html: { rows: 8 }
      f.input :faq, as: :text, input_html: { rows: 8 }
      f.input :materials, as: :text, input_html: { rows: 8 }
      f.input :cancellation_policy, as: :text, input_html: { rows: 8 }
      f.input :brochure, label: 'Link público a Brochure (pdf)'
      f.input :external_site_url
      f.input :extra_script, as: :text, input_html: { rows: 5 }
      f.input :canonical_id, as: :select, collection: EventType.all.map { |et|
                                                        [et.unique_name, et.id]
                                                      }, include_blank: '<autoref>'
      f.input :deleted
      f.input :noindex
      f.input :new_version
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

    targets = {
      'Article' => Article.all.order(:title).pluck(:title, :id),
      'EventType' => EventType.included_in_catalog.order(:name).map { |et| [et.unique_name, et.id] },
      'Service' => Service.all.order(:name).pluck(:name, :id),
      'Resource' => Resource.all.order(:title_es).pluck(:title_es, :id)
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
