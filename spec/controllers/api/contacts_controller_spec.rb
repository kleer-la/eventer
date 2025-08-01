# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ContactsController, type: :controller do
  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  let(:valid_contact_params) do
    {
      name: 'John Doe',
      email: 'john@example.com',
      company: 'Acme Corp',
      context: '/recursos',
      message: 'Test message',
      language: 'es',
      secret: 'valid_secret',
      initial_slug: 'original-page'
    }
  end

  let(:resource) do
    create(:resource,
           slug: 'agile-fundamentals',
           title_es: 'Agile Fundamentals Guide',
           getit_es: 'Obtén la guía de Fundamentos Ágiles')
  end

  let(:valid_download_params) do
    valid_contact_params.merge({
                                 resource_slug: resource.slug
                               })
  end

  describe 'POST #create' do
    context 'with valid contact us form parameters' do
      let!(:mail_template) do
        create(:mail_template, :for_contacts)
      end
      it 'creates a new contact' do
        expect do
          post :create, params: valid_contact_params
        end.to change(Contact, :count).by(1)
      end

      it 'sets trigger_type as contact_form' do
        post :create, params: valid_contact_params
        expect(Contact.last.trigger_type).to eq('contact_form')
      end

      it 'enqueues notification email' do
        expect do
          post :create, params: valid_contact_params
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('NotificationMailer', 'custom_notification', 'deliver_now', anything)
          .on_queue('default')
      end

      it 'saves form data with request information' do
        post :create, params: valid_contact_params

        contact = Contact.last
        expect(contact.email).to eq('john@example.com')
        expect(contact.form_data).to include(
          'name' => 'John Doe', # Validate name in form_data
          'message' => 'Test message',
          'page' => '/recursos'
        )
      end
      it 'saves form data with company information' do
        post :create, params: valid_contact_params

        contact = Contact.last
        expect(contact.email).to eq('john@example.com')
        expect(contact.form_data).to include(
          'name' => 'John Doe', # Validate name in form_data
          'company' => 'Acme Corp', # Validate company in form_data
          'message' => 'Test message',
          'page' => '/recursos'
        )
      end
      it 'saves form data and extracts name and company' do
        post :create, params: valid_contact_params

        contact = Contact.last
        expect(contact.email).to eq('john@example.com')
        expect(contact.name).to eq('John Doe') # Validate name is extracted
        expect(contact.company).to eq('Acme Corp') # Validate company is extracted
        expect(contact.form_data).to include(
          'name' => 'John Doe',
          'company' => 'Acme Corp',
          'message' => 'Test message',
          'page' => '/recursos'
        )
      end
    end

    context 'with invalid parameters' do
      before do
        allow_any_instance_of(ContactValidator).to receive(:valid?).and_return(false)
        allow_any_instance_of(ContactValidator).to receive(:error).and_return('validation error')
      end

      it 'does not create contact' do
        expect do
          post :create, params: valid_contact_params
        end.not_to change(Contact, :count)
      end

      it 'returns error status' do
        post :create, params: valid_contact_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'logs the error' do
        post :create, params: valid_contact_params
        last_log = Log.last

        expect(last_log.area).to eq('mail')
        expect(last_log.level).to eq('error')
        expect(last_log.message).to eq('Validation failed')

        # Test presence of key parameters in details
        expect(last_log.details).to include('name')
        expect(last_log.details).to include('john@example.com')
        expect(last_log.details).to include('/recursos')
        expect(last_log.details).to include('Test message')
      end
    end

    context 'with valid download request' do
      let!(:mail_template) do
        create(:mail_template, :for_downloads)
      end
      before { resource } # ensure resource exists

      it 'creates a new contact record' do
        expect do
          post :create, params: valid_download_params
        end.to change(Contact, :count).by(1)
      end

      it 'sets trigger_type as download' do
        post :create, params: valid_download_params
        expect(Contact.last.trigger_type).to eq('download_form')
      end

      it 'includes resource information in form_data' do
        post :create, params: valid_download_params

        form_data = Contact.last.form_data
        expect(form_data['resource_title_es']).to eq('Agile Fundamentals Guide')
        expect(form_data['resource_getit_es']).to eq('Obtén la guía de Fundamentos Ágiles')
      end

      it 'sends download notification emails' do
        expect do
          post :create, params: valid_download_params
        end.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('NotificationMailer', 'custom_notification', 'deliver_now', anything)
          .on_queue('default')
      end
      it 'returns created status with contact data' do
        post :create, params: valid_contact_params
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'id' => Contact.last.id,
          'status' => Contact.last.status,
          'assessment_report_url' => Contact.last.assessment_report_url
        )
      end
      it 'returns created status with extracted name and company' do
        post :create, params: valid_contact_params
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'id' => Contact.last.id,
          'name' => 'John Doe', # Validate name is included in response
          'company' => 'Acme Corp', # Validate company is included in response
          'status' => Contact.last.status,
          'assessment_report_url' => Contact.last.assessment_report_url
        )
      end
    end

    context 'with invalid params' do
      it 'returns validation error for missing required fields' do
        post :create, params: { email: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to have_key('error')
      end

      it 'returns error when resource_slug is invalid' do
        post :create, params: valid_contact_params.merge(resource_slug: 'non-existent')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Resource not found')
      end
    end

    context 'with language-specific templates' do
      let!(:es_template) do
        create(:mail_template, :for_contacts, lang: :es)
      end

      let!(:en_template) do
        create(:mail_template, :for_contacts, lang: :en)
      end

      before do
        allow(NotificationMailer).to receive(:custom_notification).and_return(
          double(deliver_later: true)
        )
      end

      it 'only sends notifications for templates matching contact language' do
        post :create, params: valid_contact_params.merge(
          language: 'es'
        )

        expect(NotificationMailer).to have_received(:custom_notification)
          .with(anything, es_template)
          .once

        expect(NotificationMailer).not_to have_received(:custom_notification)
          .with(anything, en_template)
      end
      it 'only sends notifications for templates matching contact language (en)' do
        post :create, params: valid_contact_params.merge(
          language: 'en'
        )

        expect(NotificationMailer).not_to have_received(:custom_notification)
          .with(anything, es_template)

        expect(NotificationMailer).to have_received(:custom_notification)
          .with(anything, en_template)
          .once
      end
    end

    describe 'multi download fields handling' do
      it 'handles missing content_updates_opt_in and newsletter_opt_in' do
        post :create, params: valid_contact_params # For controller specs, we use the action symbol

        expect(response).to have_http_status(:created)
        contact = Contact.last
        expect(contact).to be_present
        expect(contact.content_updates_opt_in).to be false
        expect(contact.newsletter_opt_in).to be false
      end

      it 'processes content_updates_opt_in correctly when on' do
        post :create, params: valid_contact_params.merge(content_updates_opt_in: 'on')

        expect(response).to have_http_status(:created)
        contact = Contact.last
        expect(contact.content_updates_opt_in).to be true
      end

      it 'processes newsletter_opt_in correctly when on' do
        post :create, params: valid_contact_params.merge(newsletter_opt_in: 'on')

        expect(response).to have_http_status(:created)
        contact = Contact.last
        expect(contact.newsletter_opt_in).to be true
      end

      it 'processes content_updates_opt_in correctly when true' do
        post :create, params: valid_contact_params.merge(content_updates_opt_in: 'true')

        expect(response).to have_http_status(:created)
        contact = Contact.last
        expect(contact.content_updates_opt_in).to be true
      end

      it 'processes newsletter_opt_in correctly when true' do
        post :create, params: valid_contact_params.merge(newsletter_opt_in: 'true')

        expect(response).to have_http_status(:created)
        contact = Contact.last
        expect(contact.newsletter_opt_in).to be true
      end

      context 'when resource download includes initial_slug' do
        let!(:resource) { create(:resource, slug: 'test-resource') }

        it 'maintains initial_slug different from resource_slug' do
          post :create, params: valid_contact_params.merge(
            resource_slug: 'test-resource',
            initial_slug: 'came-from-here'
          )

          expect(response).to have_http_status(:created)
          contact = Contact.last
          expect(contact).to be_present
          expect(contact.form_data['initial_slug']).to eq('came-from-here')
          expect(contact.form_data['resource_slug']).to eq('test-resource')
        end
      end
    end
  end

  describe 'GET #show' do
    let!(:contact) { create(:contact) }

    context 'with a valid contact ID' do
      it 'returns the contact details' do
        get :show, params: { id: contact.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'id' => contact.id,
          'email' => contact.email
        )
      end
    end

    context 'with an invalid contact ID' do
      it 'returns a not found error' do
        get :show, params: { id: 'non-existent-id' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Contact not found')
      end
    end
  end

  describe 'error logging' do
    it 'logs contact save errors' do
      contact = Contact.new # Real instance
      allow(contact).to receive(:errors).and_return(double(full_messages: ['Test error message']))
      allow_any_instance_of(Contact).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(contact))

      post :create, params: valid_contact_params

      last_log = Log.last
      expect(last_log.area).to eq('mail')
      expect(last_log.level).to eq('error')
      expect(last_log.message).to eq('Validation failed during processing')
      expect(last_log.details).to include('Test error message')
    end

    it 'logs unexpected errors' do
      allow_any_instance_of(Contact).to receive(:save!).and_raise(StandardError.new('Unexpected error'))

      post :create, params: valid_contact_params

      expect(response).to have_http_status(500)
      last_log = Log.last
      expect(last_log.area).to eq('mail')
      expect(last_log.level).to eq('error')
      expect(last_log.message).to eq('Unexpected error')
      expect(last_log.details).to include('Unexpected error')
      expect(last_log.details).to include('backtrace')
    end
  end
  describe 'an assessment' do
    let(:question) { create(:question, id: 1) }
    let(:answer) { create(:answer, id: 5) }
    let(:assessment) { create(:assessment) }
    let(:assessment_resources) do
      resource = create(:resource, slug: 'un-assessment', title_es: 'Un Assessment')
      assessment.update!(resource: resource)
      resource
    end
    let(:valid_assessment_params) do
      valid_contact_params.merge({ resource_slug: 'un-assessment',
                                   resource_title_es: 'Un Assessment',
                                   assessment_id: assessment.id.to_s,
                                   assessment_results: { '1' => '5' } })
    end
    let(:contact) { Contact.last }

    before do
      question
      answer
      assessment_resources
    end

    it 'creates a new contact with the correct form data' do
      post :create, params: valid_assessment_params

      expect(response).to have_http_status(:created)
      expect(contact.form_data).to include(
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'company' => 'Acme Corp',
        'page' => '/recursos',
        'language' => 'es',
        'resource_title_es' => 'Un Assessment',
        'resource_slug' => 'un-assessment',
        'assessment_id' => assessment.id.to_s,
        'assessment_results' => { '1' => '5' }
      )
    end
    it 'creates responses for assessment results' do
      post :create, params: valid_assessment_params

      expect(response).to have_http_status(:created)
      expect(contact.responses.count).to eq(1)
      expect(contact.responses.pluck(:question_id, :answer_id)).to contain_exactly(
        [1, 5]
      )
    end

    context 'assessment report generation' do
      it 'should enqueue assessment report generation job' do
        # This test will FAIL when the job is commented out (reproducing the bug)
        # and PASS when the job is uncommented (fixing the bug)
        expect do
          post :create, params: valid_assessment_params
        end.to have_enqueued_job(GenerateAssessmentResultJob)
          .on_queue('default')
      end

      it 'sets trigger_type correctly for assessment submission' do
        post :create, params: valid_assessment_params

        expect(contact.trigger_type).to eq('assessment_submission')
      end

      it 'creates responses successfully' do
        post :create, params: valid_assessment_params

        # Responses are created successfully
        expect(contact.responses.count).to eq(1)
        expect(contact.responses.pluck(:question_id, :answer_id)).to contain_exactly([1, 5])
      end

      it 'starts with pending status before job processing' do
        post :create, params: valid_assessment_params

        # Contact starts in pending status, will be updated by the job
        expect(contact.status).to eq('pending')
        expect(contact.assessment_report_url).to be_nil
      end
    end
  end

  describe 'GenerateAssessmentResultJob' do
    let(:question1) { create(:question, name: 'lean-agile') }
    let(:question2) { create(:question, name: 'training') }
    let(:answer1) { create(:answer, question: question1, position: 4) }
    let(:answer2) { create(:answer, question: question2, position: 2) }
    let(:assessment) { create(:assessment) }
    let(:contact) do
      create(:contact, 
        trigger_type: 'assessment_submission', 
        assessment_id: assessment.id,
        status: 'pending'
      )
    end

    before do
      question1
      question2
      answer1
      answer2
      assessment
      
      # Create responses for the contact
      contact.responses.create!(question: question1, answer: answer1)
      contact.responses.create!(question: question2, answer: answer2)
    end

    it 'handles assessments with fewer than 3 competencies' do
      # Mock the file store service to avoid actual S3 uploads
      allow(FileStoreService).to receive(:current).and_return(
        double(upload: 'https://example.com/test.pdf')
      )
      
      # Mock file operations
      allow(File).to receive(:write)
      allow(Rails.root).to receive(:join).and_return('/tmp/test_path')
      
      # Mock Gruff chart generation
      chart_mock = double('CustomSpider')
      allow(CustomSpider).to receive(:new).and_return(chart_mock)
      allow(chart_mock).to receive(:data)
      allow(chart_mock).to receive(:theme=)
      allow(chart_mock).to receive(:write)
      
      # Mock Prawn PDF generation
      pdf_mock = double('Prawn::Document')
      allow(Prawn::Document).to receive(:generate).and_yield(pdf_mock)
      allow(pdf_mock).to receive(:text)
      allow(pdf_mock).to receive(:image)
      allow(pdf_mock).to receive(:move_down)

      # Execute the job
      job = GenerateAssessmentResultJob.new
      job.perform(contact.id)

      # Verify the job completed successfully
      contact.reload
      expect(contact.status).to eq('completed')
      expect(contact.assessment_report_url).to eq('https://example.com/test.pdf')
      
      # Verify that the chart was created with at least 3 data points
      # (the job should add a placeholder to meet the minimum requirement)
      expect(CustomSpider).to have_received(:new).with(5)
      expect(chart_mock).to have_received(:data).at_least(3).times
    end

    it 'processes competencies correctly with sufficient data' do
      # Add a third question to have enough data points
      question3 = create(:question, name: 'facilitacion')
      answer3 = create(:answer, question: question3, position: 3)
      contact.responses.create!(question: question3, answer: answer3)
      
      # Mock the file store service
      allow(FileStoreService).to receive(:current).and_return(
        double(upload: 'https://example.com/test.pdf')
      )
      
      # Mock file operations
      allow(File).to receive(:write)
      allow(Rails.root).to receive(:join).and_return('/tmp/test_path')
      
      # Mock Gruff chart generation
      chart_mock = double('CustomSpider')
      allow(CustomSpider).to receive(:new).and_return(chart_mock)
      allow(chart_mock).to receive(:data)
      allow(chart_mock).to receive(:theme=)
      allow(chart_mock).to receive(:write)
      
      # Mock Prawn PDF generation
      pdf_mock = double('Prawn::Document')
      allow(Prawn::Document).to receive(:generate).and_yield(pdf_mock)
      allow(pdf_mock).to receive(:text)
      allow(pdf_mock).to receive(:image)
      allow(pdf_mock).to receive(:move_down)

      # Execute the job
      job = GenerateAssessmentResultJob.new
      job.perform(contact.id)

      # Verify the job completed successfully
      contact.reload
      expect(contact.status).to eq('completed')
      expect(contact.assessment_report_url).to eq('https://example.com/test.pdf')
      
      # Verify that the chart was created with exactly 3 data points (no placeholders needed)
      expect(CustomSpider).to have_received(:new).with(5)
      expect(chart_mock).to have_received(:data).exactly(3).times
    end

    it 'sets contact status to failed when job encounters an error' do
      # Mock the file store service to return a valid store initially
      store_mock = double('FileStoreService')
      allow(FileStoreService).to receive(:current).and_return(store_mock)
      
      # Mock file operations
      allow(File).to receive(:write)
      allow(Rails.root).to receive(:join).and_return('/tmp/test_path')
      
      # Mock Gruff chart generation to work initially
      chart_mock = double('CustomSpider')
      allow(CustomSpider).to receive(:new).and_return(chart_mock)
      allow(chart_mock).to receive(:data)
      allow(chart_mock).to receive(:theme=)
      allow(chart_mock).to receive(:write)
      
      # Mock Prawn PDF generation
      pdf_mock = double('Prawn::Document')
      allow(Prawn::Document).to receive(:generate).and_yield(pdf_mock)
      allow(pdf_mock).to receive(:text)
      allow(pdf_mock).to receive(:image)
      allow(pdf_mock).to receive(:move_down)
      
      # Make the upload operation fail (this happens after in_progress is set)
      allow(store_mock).to receive(:upload).and_raise(StandardError.new('S3 upload failed'))
      
      # Execute the job and expect it to handle the error
      job = GenerateAssessmentResultJob.new
      expect {
        job.perform(contact.id)
      }.to raise_error(StandardError, 'S3 upload failed')

      # Verify the contact status was set to failed
      contact.reload
      expect(contact.status).to eq('failed')
      expect(contact.assessment_report_url).to be_nil
    end
  end

  describe 'GET #status' do
    let(:contact) { create(:contact, status: :pending) }

    it 'returns contact status and assessment report URL' do
      get :status, params: { contact_id: contact.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to include(
        'status' => 'pending',
        'assessment_report_url' => nil
      )
    end

    it 'returns contact status when completed' do
      contact.update!(status: :completed, assessment_report_url: 'https://example.com/report.pdf')

      get :status, params: { contact_id: contact.id }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to include(
        'status' => 'completed',
        'assessment_report_url' => 'https://example.com/report.pdf'
      )
    end

    context 'with rule-based assessment' do
      let(:assessment) { create(:assessment, rule_based: true) }
      let(:contact) { create(:contact, assessment: assessment, status: :completed) }
      let(:html_content) { '<html><body><h1>Test Report</h1></body></html>' }

      before do
        contact.update!(
          assessment_report_url: 'https://example.com/report.pdf',
          assessment_report_html: html_content
        )
      end

      it 'returns HTML content and rule_based flag' do
        get :status, params: { contact_id: contact.id }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to include(
          'status' => 'completed',
          'assessment_report_url' => 'https://example.com/report.pdf',
          'assessment_report_html' => html_content,
          'assessment' => { 'rule_based' => true }
        )
      end
    end

    it 'returns 404 for non-existent contact' do
      get :status, params: { contact_id: 'non-existent' }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'assessments with text-based questions' do
    let(:short_text_question) { create(:question, :short_text, assessment: assessment, id: 10) }
    let(:long_text_question) { create(:question, :long_text, assessment: assessment, id: 11) }
    let(:assessment) { create(:assessment) }
    let(:assessment_resources) do
      resource = create(:resource, slug: 'text-assessment', title_es: 'Text Assessment')
      assessment.update!(resource: resource)
      resource
    end
    let(:valid_text_assessment_params) do
      valid_contact_params.merge({
        resource_slug: 'text-assessment',
        resource_title_es: 'Text Assessment',
        assessment_id: assessment.id.to_s,
        assessment_results: {
          '10' => 'This is my short answer',
          '11' => 'This is my much longer and more detailed answer that spans multiple sentences and provides comprehensive information.'
        }
      })
    end
    let(:contact) { Contact.last }

    before do
      short_text_question
      long_text_question
      assessment_resources
    end

    it 'creates a new contact with text assessment results' do
      post :create, params: valid_text_assessment_params

      expect(response).to have_http_status(:created)
      expect(contact.form_data).to include(
        'assessment_id' => assessment.id.to_s,
        'assessment_results' => {
          '10' => 'This is my short answer',
          '11' => 'This is my much longer and more detailed answer that spans multiple sentences and provides comprehensive information.'
        }
      )
    end

    it 'creates text responses for text-based questions' do
      post :create, params: valid_text_assessment_params

      expect(response).to have_http_status(:created)
      expect(contact.responses.count).to eq(2)
      
      short_response = contact.responses.find_by(question: short_text_question)
      long_response = contact.responses.find_by(question: long_text_question)
      
      expect(short_response.text_response).to eq('This is my short answer')
      expect(short_response.answer).to be_nil
      
      expect(long_response.text_response).to eq('This is my much longer and more detailed answer that spans multiple sentences and provides comprehensive information.')
      expect(long_response.answer).to be_nil
    end

    it 'enqueues assessment report generation job for text assessments' do
      expect do
        post :create, params: valid_text_assessment_params
      end.to have_enqueued_job(GenerateAssessmentResultJob)
        .on_queue('default')
    end

    it 'sets trigger_type correctly for text assessment submission' do
      post :create, params: valid_text_assessment_params

      expect(contact.trigger_type).to eq('assessment_submission')
    end
  end

  describe 'assessments with mixed question types' do
    let(:linear_question) { create(:question, :linear_scale, assessment: assessment, id: 20) }
    let(:short_text_question) { create(:question, :short_text, assessment: assessment, id: 21) }
    let(:radio_question) { create(:question, :radio_button, assessment: assessment, id: 22) }
    let(:linear_answer) { create(:answer, question: linear_question, id: 50) }
    let(:radio_answer) { create(:answer, question: radio_question, id: 51) }
    let(:assessment) { create(:assessment) }
    let(:assessment_resources) do
      resource = create(:resource, slug: 'mixed-assessment', title_es: 'Mixed Assessment')
      assessment.update!(resource: resource)
      resource
    end
    let(:valid_mixed_assessment_params) do
      valid_contact_params.merge({
        resource_slug: 'mixed-assessment',
        resource_title_es: 'Mixed Assessment',
        assessment_id: assessment.id.to_s,
        assessment_results: {
          '20' => '50',  # linear_scale answer_id
          '21' => 'My text response',  # short_text response
          '22' => '51'   # radio_button answer_id
        }
      })
    end
    let(:contact) { Contact.last }

    before do
      linear_question
      short_text_question
      radio_question
      linear_answer
      radio_answer
      assessment_resources
    end

    it 'creates responses for mixed question types correctly' do
      post :create, params: valid_mixed_assessment_params

      expect(response).to have_http_status(:created)
      expect(contact.responses.count).to eq(3)
      
      linear_response = contact.responses.find_by(question: linear_question)
      text_response = contact.responses.find_by(question: short_text_question)
      radio_response = contact.responses.find_by(question: radio_question)
      
      expect(linear_response.answer_id).to eq(50)
      expect(linear_response.text_response).to be_nil
      
      expect(text_response.text_response).to eq('My text response')
      expect(text_response.answer).to be_nil
      
      expect(radio_response.answer_id).to eq(51)
      expect(radio_response.text_response).to be_nil
    end
  end
end
