ActiveAdmin.register Rule do
  menu parent: 'We Publish'
  permit_params :assessment_id, :position, :diagnostic_text, :conditions

  # Scope by assessment when assessment_id is provided
  controller do
    def scoped_collection
      if params[:assessment_id].present?
        end_of_association_chain.where(assessment_id: params[:assessment_id])
      else
        end_of_association_chain
      end
    end

    def new
      @rule = Rule.new
      @rule.assessment_id = params[:assessment_id] if params[:assessment_id]
      super
    end
  end

  index do
    selectable_column
    id_column
    column :assessment do |rule|
      link_to rule.assessment.title, admin_assessment_path(rule.assessment)
    end
    column :position
    column :diagnostic_text do |rule|
      truncate(rule.diagnostic_text, length: 80)
    end
    column :conditions do |rule|
      content_tag :code, truncate(rule.conditions, length: 60), style: 'font-size: 11px;'
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :assessment do |rule|
        link_to rule.assessment.title, admin_assessment_path(rule.assessment)
      end
      row :position
      row :diagnostic_text
      row :conditions do |rule|
        content_tag :pre, rule.conditions, style: 'background: #f5f5f5; padding: 10px; border-radius: 4px; font-size: 12px;'
      end
      row :created_at
      row :updated_at
    end

    panel 'Rule Conditions Breakdown' do
      rule_conditions = rule.parsed_conditions
      if rule_conditions.any?
        table do
          thead do
            tr do
              th 'Question ID'
              th 'Condition Type'
              th 'Expected Value'
            end
          end
          tbody do
            rule_conditions.each do |question_id_str, condition_data|
              tr do
                td do
                  question_id = question_id_str.to_i
                  question = Question.find_by(id: question_id)
                  if question
                    "#{question_id} - #{question.name}"
                  else
                    "#{question_id} (Question not found)"
                  end
                end
                td do
                  if condition_data.is_a?(Hash)
                    condition_data.keys.join(', ')
                  else
                    'Any value (null)'
                  end
                end
                td do
                  if condition_data.is_a?(Hash)
                    condition_data.values.join(', ')
                  else
                    'Any response'
                  end
                end
              end
            end
          end
        end
      else
        div class: 'blank_slate_container' do
          span class: 'blank_slate' do
            'No valid conditions found. Check JSON syntax.'
          end
        end
      end
    end

    panel 'Rule Testing' do
      div do
        para "This rule will match responses where:"
        ul do
          rule.parsed_conditions.each do |question_id_str, condition|
            question = Question.find_by(id: question_id_str.to_i)
            question_name = question ? question.name : "Question #{question_id_str}"
            
            if condition.nil?
              li "#{question_name}: Any response"
            elsif condition.is_a?(Hash)
              condition.each do |type, value|
                case type
                when 'value'
                  li "#{question_name}: Exact value = #{value}"
                when 'range'
                  li "#{question_name}: Value between #{value[0]} and #{value[1]} (inclusive)"
                when 'text_contains'
                  li "#{question_name}: Text contains '#{value}'"
                else
                  li "#{question_name}: #{type} = #{value}"
                end
              end
            end
          end
        end
      end
    end
  end

  form do |f|
    f.inputs 'Rule Details' do
      if params[:assessment_id].present?
        f.input :assessment_id, as: :hidden, input_html: { value: params[:assessment_id] }
        assessment = Assessment.find(params[:assessment_id])
        f.semantic_errors :assessment_id
        div class: 'input' do
          label 'Assessment', class: 'label'
          div class: 'input' do
            strong assessment.title
          end
        end
      else
        f.input :assessment, as: :select, collection: Assessment.all.order(:title).pluck(:title, :id), include_blank: false
      end
      
      f.input :position, hint: 'Rules are evaluated in order of position (1, 2, 3...)'
      f.input :diagnostic_text, as: :text, input_html: { rows: 4 }, hint: 'Text that will appear in the assessment report when this rule matches'
    end

    f.inputs 'Rule Conditions' do
      f.input :conditions, as: :text, input_html: { rows: 8, style: 'font-family: monospace; font-size: 12px;' },
              hint: raw('JSON format specifying when this rule should match. Examples:<br/>' +
                       '<strong>Exact value:</strong> {"123": {"value": 3}}<br/>' +
                       '<strong>Range:</strong> {"123": {"range": [2, 4]}}<br/>' +
                       '<strong>Text contains:</strong> {"123": {"text_contains": "leadership"}}<br/>' +
                       '<strong>Any response:</strong> {"123": null}<br/>' +
                       '<strong>Multiple conditions:</strong> {"123": {"value": 3}, "456": {"range": [1, 5]}}<br/>' +
                       'Replace "123", "456" with actual Question IDs from this assessment.')
    end

    if f.object.assessment_id.present?
      assessment = Assessment.find(f.object.assessment_id)
      panel 'Available Questions', style: 'margin-top: 20px; padding: 15px; background: #f9f9f9; border: 1px solid #ddd;' do
        div style: 'font-size: 13px;' do
          strong 'Questions in this assessment:'
          ul style: 'margin-top: 10px;' do
            assessment.questions.order(:position).each do |question|
              li do
                span "ID: #{question.id} - #{question.name} [#{question.question_type.humanize}]"
                if question.answers.any?
                  ul style: 'margin-left: 20px; color: #666;' do
                    question.answers.order(:position).each do |answer|
                      li "#{answer.position}: #{answer.text}"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    f.actions
  end

  # Add custom action to test rule
  member_action :test, method: :get do
    @rule = Rule.find(params[:id])
    @assessment = @rule.assessment
    @test_contacts = @assessment.contacts.includes(:responses).limit(10)
  end

  action_item :test_rule, only: :show do
    link_to 'Test Rule', test_admin_rule_path(resource), class: 'button'
  end
end