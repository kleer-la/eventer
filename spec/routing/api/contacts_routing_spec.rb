require 'rails_helper'

RSpec.describe 'API Contacts Routes', type: :routing do
  describe 'routing' do
    it 'routes POST /api/contact_us to api/contacts#contact_us' do
      expect(post: '/api/contact_us').to route_to(
        controller: 'api/contacts',
        action: 'contact_us'
      )
    end
  end
end
