ActiveAdmin.register Assessment do
  menu parent: 'We Publish'
  permit_params :title, :description, :resource_id, # Moved :resource_id here
                question_groups_attributes: [:id, :name, :description, :position, :_destroy, # Added :description, :_destroy, removed :resource_id
                                             { questions_attributes: [:id, :name, :description, :position, :question_type, :_destroy,
                                                                      { answers_attributes: %i[id text position _destroy] }] }],
                questions_attributes: [:id, :name, :description, :position, :question_type, :_destroy,
                                       { answers_attributes: %i[id text position _destroy] }]

  index do
    selectable_column
    id_column
    column :title
    column :description
    column :resource do |assessment|
      assessment.resource&.title_es
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :title
      row :description
      row :resource do |assessment|
        assessment.resource&.title_es
      end
      row :created_at
    end

    panel 'Question Groups' do
      table_for assessment.question_groups.order(:position) do
        column :name
        column :position
        column 'Questions' do |group|
          ul do
            group.questions.order(:position).each do |question|
              li "#{question.name} [#{question.question_type.humanize}] (#{question.answers.pluck(:text).join(', ')})"
            end
          end
        end
      end
    end

    panel 'Standalone Questions' do
      table_for assessment.questions.where(question_group_id: nil).order(:position) do
        column :name
        column :question_type do |question|
          question.question_type.humanize
        end
        column :position
        column 'Answers' do |question|
          question.answers.pluck(:text).join(', ')
        end
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :title
      f.input :description
      f.input :resource, as: :select, collection: Resource.all.pluck(:title_es, :id), include_blank: true
    end

    f.has_many :question_groups, heading: 'Question Groups', allow_destroy: true, new_record: true do |qg|
      qg.input :name
      qg.input :description
      qg.input :position
      qg.has_many :questions, heading: 'Questions in Group', allow_destroy: true, new_record: true do |q|
        q.input :name
        q.input :description
        q.input :position
        q.input :question_type, as: :select, collection: [
          ['Linear Scale', 'linear_scale'],
          ['Radio Button', 'radio_button'],
          ['Short Text', 'short_text'],
          ['Long Text', 'long_text']
        ], include_blank: false
        q.has_many :answers, heading: 'Answers', allow_destroy: true, new_record: true do |a|
          a.input :text
          a.input :position
        end
      end
    end

    f.has_many :questions, heading: 'Standalone Questions', allow_destroy: true, new_record: true do |q|
      q.input :name
      q.input :description
      q.input :position
      q.input :question_type, as: :select, collection: [
        ['Linear Scale', 'linear_scale'],
        ['Radio Button', 'radio_button'],
        ['Short Text', 'short_text'],
        ['Long Text', 'long_text']
      ], include_blank: false
      q.has_many :answers, heading: 'Answers', allow_destroy: true, new_record: true do |a|
        a.input :text
        a.input :position
      end
    end

    f.actions
  end
end
