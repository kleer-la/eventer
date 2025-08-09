# spec/system/admin/images_spec.rb
require 'rails_helper'

RSpec.describe 'Admin Images', type: :system do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { create(:admin_user) }
  let(:image_url) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/test.jpg' }

  before do
    driven_by(:rack_test)
    sign_in admin_user
    
    # Mock AWS S3 client creation to prevent real AWS calls
    mock_client = double('Aws::S3::Client')
    mock_resource = double('Aws::S3::Resource') 
    mock_bucket = double('Aws::S3::Bucket')
    
    allow(Aws::S3::Client).to receive(:new).and_return(mock_client)
    allow(Aws::S3::Resource).to receive(:new).and_return(mock_resource)
    allow(mock_resource).to receive(:bucket).and_return(mock_bucket)
  end

  describe 'index page' do
    before do
      # Mock FileStoreService responses
      allow_any_instance_of(FileStoreService).to receive(:list).and_return([
                                                                             OpenStruct.new(
                                                                               key: 'la_revolucion_agil/cap7/01. MINIATURA EP7.png',
                                                                               last_modified: Time.new(2023, 8, 31, 20,
                                                                                                       28, 58),
                                                                               size: 1_342_177 # 1.28 MB in bytes
                                                                             )
                                                                           ])

      visit admin_images_path
    end

    it 'shows the filters sidebar' do
      within '#filters_sidebar_section' do
        expect(page).to have_content('Filters')
        expect(page).to have_css('label', text: 'Minimum Size (KB)')
        expect(page).to have_css('label', text: 'Extension')
        expect(page).to have_button('Filter')
        expect(page).to have_link('Clear Filters')
      end
    end

    it 'shows image information in the table' do
      within 'table' do
        # Check headers
        expect(page).to have_css('th', text: 'Name')
        expect(page).to have_css('th', text: 'Extensions')
        expect(page).to have_css('th', text: 'Modified')
        expect(page).to have_css('th', text: 'Size')
        expect(page).to have_css('th', text: 'Actions')

        # Check content
        expect(page).to have_content('01. MINIATURA EP7')
        expect(page).to have_link('png',
                                  href: '/admin/images/show?bucket=image&key=la_revolucion_agil%2Fcap7%2F01.+MINIATURA+EP7.png')
        expect(page).to have_content('2023-08-31 20:28:58')
        expect(page).to have_content('1.28 MB')

        # Check actions dropdown
        within '.dropdown_menu' do
          expect(page).to have_link('Actions')
          find('.dropdown_menu_button').click
          expect(page).to have_link('View .png')
          expect(page).to have_link('Usage .png')
        end
      end
    end
  end
  describe 'usage page' do
    let!(:event_type) { create(:event_type, cover: image_url) }

    before do
      allow(FileStoreService).to receive(:image_url).and_return(image_url)
      visit admin_images_usage_path(bucket: 'image', key: 'test.jpg')
    end

    it 'shows the page title' do
      expect(page).to have_content('Image Usage - test.jpg')
    end

    it 'shows image preview' do
      within '.columns .column:first-child .panel', text: 'Image Preview' do
        expect(page).to have_css("img[style*='max-width: 300px']")
        expect(page).to have_css("img[src='#{image_url}']")
      end
    end

    it 'shows usage information when image is in use' do
      allow(ImageUsageService).to receive(:find_usage).and_return({
                                                                    event_type: [{
                                                                      id: event_type.id,
                                                                      field: :cover,
                                                                      type: 'direct'
                                                                    }]
                                                                  })

      visit admin_images_usage_path(bucket: 'image', key: 'test.jpg')

      expect(page).not_to have_content('This image is not currently in use')
      # expect(page).to have_content('EventType')
      # expect(page).to have_content("ID: #{event_type.id}")

      expect(page).not_to have_button('Delete Image')
    end

    context 'when image is not in use' do
      before do
        allow(ImageUsageService).to receive(:find_usage).and_return({})
        visit admin_images_usage_path(bucket: 'image', key: 'test.jpg')
      end

      it 'shows no usage message and delete button' do
        expect(page).to have_content('This image is not currently in use in any model')

        expect(page).to have_button('Delete Image')
        expect(page).to have_css("form.button_to[action*='/admin/images/delete']")
      end
    end
  end

  # describe 'delete action' do
  #   context 'when image is not in use' do
  #     before do
  #       test_image_url = 'https://kleer-images.s3.sa-east-1.amazonaws.com/test.jpg'
  #       allow(FileStoreService).to receive(:image_url).and_return(test_image_url)
  #       allow(ImageUsageService).to receive(:find_usage).and_return({})
  #       allow_any_instance_of(FileStoreService).to receive(:delete).and_return(true)
  #     end

  #     it 'allows deletion and redirects to index' do
  #       visit admin_images_usage_path(bucket: 'image', key: 'test.jpg')

  #       expect(page).to have_button('Delete Image')
  #       click_button 'Delete Image' # Just click without handling confirmation

  #       expect(page).to have_current_path(admin_images_path)
  #       expect(page).to have_content('Image successfully deleted')
  #     end
  #   end
  # end

  describe 'usage page with new models' do
    let(:image_with_models) { 'https://kleer-images.s3.sa-east-1.amazonaws.com/multi-model-image.jpg' }
    let!(:news) { create(:news, img: image_with_models) }
    let!(:coupon) { create(:coupon, icon: image_with_models) }
    let!(:assessment) { create(:assessment, description: "Assessment with #{image_with_models}") }
    let!(:question) { create(:question, assessment: assessment, description: "Question with #{image_with_models}") }
    let!(:answer) { create(:answer, question: question, text: "Answer with #{image_with_models}") }
    let!(:question_group) do
      create(:question_group, assessment: assessment, description: "Group with #{image_with_models}")
    end

    before do
      allow(FileStoreService).to receive(:image_url).and_return(image_with_models)
      visit admin_images_usage_path(bucket: 'image', key: 'multi-model-image.jpg')
    end

    it 'shows usage across all registered models' do
      # Should show that image is in use
      expect(page).not_to have_content('This image is not currently in use')
      expect(page).not_to have_button('Delete Image')

      # Should show all model types that have this image
      expect(page).to have_content('News')
      expect(page).to have_content('Coupon')
      expect(page).to have_content('Assessment')
      expect(page).to have_content('Question')
      expect(page).to have_content('Answer')
      expect(page).to have_content('Question Group')
    end

    it 'provides appropriate links for models with admin resources' do
      # Models with admin resources should have direct links
      expect(page).to have_link('View news')
      expect(page).to have_link('View coupon')
      expect(page).to have_link('View assessment')
    end

    it 'provides fallback links for models without admin resources' do
      # Question, Answer, QuestionGroup should link to their parent Assessment
      # Since they don't have their own admin resources
      expect(page).to have_link('View Assessment').at_least(3) # For question, answer, question_group
    end

    it 'shows field and type information for all usage instances' do
      # Check that all instances show proper field and type information
      # News: direct reference in img field
      expect(page).to have_content('img')
      expect(page).to have_content('direct')

      # Coupon: direct reference in icon field
      expect(page).to have_content('icon')

      # Assessment, Question, Answer, QuestionGroup: embedded references in text fields
      expect(page).to have_content('description')
      expect(page).to have_content('text')
      expect(page).to have_content('embedded')
    end
  end
end
