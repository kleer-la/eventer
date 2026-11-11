# frozen_string_literal: true

require 'rails_helper'

# Every admin form that edits recommendations offers the same target types the
# model accepts (Recommendable.recommended_content_targets), so a service area
# or a flagship page can be recommended from the admin too, not only via MCP.
RSpec.describe 'Admin recommended content types', type: :system do
  include Devise::Test::IntegrationHelpers

  before do
    driven_by(:rack_test)
    sign_in create(:admin_user)
    # The event type form lists the S3 images for its pickers.
    allow_any_instance_of(FileStoreService).to receive(:list).and_return([])
  end

  {
    article: :edit_admin_article_path,
    event_type: :edit_admin_event_type_path,
    page: :edit_admin_page_path,
    resource: :edit_admin_resource_path,
    service_area: :edit_admin_service_area_path,
    service: :edit_admin_service_path
  }.each do |factory, edit_path|
    it "the #{factory} form offers every target type" do
      source = create(factory)
      # An existing row makes the form render the type select.
      create(:recommended_content, source:, target: create(:article))

      visit public_send(edit_path, source)

      options = all('select.target-type-select').first.all('option').map(&:value).compact_blank
      expect(options).to match_array(Article.recommended_content_targets.keys)
      # ...and the script that fills the target list knows each of them.
      options.each { |type| expect(page.html).to include("\"#{type}\":[") }
    end
  end
end
