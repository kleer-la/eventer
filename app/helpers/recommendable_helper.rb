# frozen_string_literal: true

module RecommendableHelper
  def self.recommended_content_js(resource_class)
    <<-JS
      $(document).ready(function() {
        window.targetOptions = #{resource_class.recommended_content_targets.to_json};

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
