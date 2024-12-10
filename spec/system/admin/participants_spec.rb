require 'rails_helper'

RSpec.describe 'Admin Participants Index', type: :system do
  include Devise::Test::IntegrationHelpers
  let(:admin_user) { create(:admin_user) }

  before do
    driven_by(:rack_test)
    sign_in admin_user
  end

  context 'with no participants' do
    before do
      visit admin_participants_path
    end

    it 'shows empty message' do
      expect(page).to have_content('There are no Participants yet')
    end

    it 'shows filter options' do
      within '#filters_sidebar_section' do
        # Check filter labels
        expect(page).to have_css('label', text: 'Email')
        expect(page).to have_css('label', text: 'Fname')
        expect(page).to have_css('label', text: 'Lname')
        expect(page).to have_css('label', text: 'Event')
        expect(page).to have_css('label', text: 'Status')
        expect(page).to have_css('label', text: 'Verification code')

        # Check filter inputs exist
        expect(page).to have_css('#q_email')
        expect(page).to have_css('#q_fname')
        expect(page).to have_css('#q_lname')
        expect(page).to have_css('#q_event_id')
        expect(page).to have_css('#q_status')
        expect(page).to have_css('#q_verification_code')

        # Check filter action buttons
        expect(page).to have_button('Filter')
        expect(page).to have_link('Clear Filters')
      end
    end
  end

  context 'with existing participants' do
    let!(:event_type) { create(:event_type, name: 'Test Event') }
    let!(:event) { create(:event, date: Date.new(2024, 1, 1), event_type:) }
    let!(:participant) do
      create(:participant,
             event:,
             fname: 'John',
             lname: 'Doe',
             email: 'john@example.com',
             quantity: 2,
             status: 'N')
    end

    before do
      visit admin_participants_path
    end

    it 'displays participant information in the table' do
      within 'table.index_table' do
        expect(page).to have_content('2024-01-01 - Test Event') # Event column
        expect(page).to have_content('John Doe') # Name column
        expect(page).to have_content('john@example.com') # Email column
        expect(page).to have_content('2') # Qty column
        expect(page).to have_content('5555-5555') # Phone number
        expect(page).to have_content('Pago Largo 123') # Address
        expect(page).to have_content('Nuevo') # Status column
      end
    end
    it 'has action links' do
      within 'table.index_table' do
        expect(page).to have_link('View')
      end
    end
  end
  context 'with many participants' do
    let!(:event_type) { create(:event_type, name: 'Test Event') }
    let!(:event) { create(:event, date: Date.new(2024, 1, 1), event_type:) }

    before do
      # Create more than one page of participants
      30.times do |i|
        create(:participant,
               event:,
               fname: "John#{i}",
               lname: "Doe#{i}",
               email: "john#{i}@example.com",
               quantity: 1,
               status: 'N')
      end
      visit admin_participants_path
    end

    it 'displays pagination' do
      expect(page).to have_css('.pagination')
    end

    it 'limits the number of participants shown' do
      expect(page).to have_selector('table.index_table tbody tr', count: 25)
    end

    it 'shows the total number of participants' do
      expect(page).to have_content('Displaying Participants 1 - 25 of 30')
    end
  end
end
