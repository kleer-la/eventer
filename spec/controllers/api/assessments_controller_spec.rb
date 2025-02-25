require 'rails_helper'

RSpec.describe Api::AssessmentsController, type: :controller do
  describe 'GET #show' do
    let(:assessment) { create(:assessment, title: 'Test Assessment', description: 'Test Description') }
    let!(:group) { create(:question_group, assessment:, name: 'Domain', position: 1) }
    let!(:grouped_question) do
      create(:question, assessment:, question_group: group, name: 'Grouped Q1', position: 1)
    end
    let!(:standalone_question) { create(:question, assessment:, name: 'Standalone Q1', position: 2) }
    let!(:grouped_answer) { create(:answer, question: grouped_question, text: 'Low', position: 1) }
    let!(:standalone_answer) { create(:answer, question: standalone_question, text: 'Small', position: 1) }

    before do
      get :show, params: { id: assessment.id }
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(:success)
    end

    it 'returns the assessment with nested groups, questions, and answers' do
      json = JSON.parse(response.body)

      # Assessment details
      expect(json['title']).to eq('Test Assessment')
      expect(json['description']).to eq('Test Description')

      # Question groups
      expect(json['question_groups'].size).to eq(1)
      expect(json['question_groups'][0]['name']).to eq('Domain')
      expect(json['question_groups'][0]['position']).to eq(1)

      # Grouped questions
      expect(json['question_groups'][0]['questions'].size).to eq(1)
      expect(json['question_groups'][0]['questions'][0]['name']).to eq('Grouped Q1')
      expect(json['question_groups'][0]['questions'][0]['answers'][0]['text']).to eq('Low')

      # Standalone questions
      expect(json['questions'].size).to eq(1)
      expect(json['questions'][0]['name']).to eq('Standalone Q1')
      expect(json['questions'][0]['answers'][0]['text']).to eq('Small')
    end
  end
end
