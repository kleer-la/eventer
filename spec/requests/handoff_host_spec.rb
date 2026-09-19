# frozen_string_literal: true

require 'rails_helper'

# The session-handoff host (#203): its root is the account page, so the people
# using the plugin never see eventos.kleer.la. Everywhere else the root is the admin.
RSpec.describe 'Handoff host', type: :request do
  it 'serves the account page at the root of the handoff host' do
    get '/', headers: { 'HOST' => 'qa.handoff.kleer.la' }

    expect(response).to have_http_status(:redirect)
    expect(response.location).to eq 'http://qa.handoff.kleer.la/handoff/sign_in'
  end

  it 'keeps the admin at the root of any other host' do
    get '/', headers: { 'HOST' => 'qa.eventos.kleer.la' }

    expect(response.location).to eq 'http://qa.eventos.kleer.la/users/sign_in'
  end
end
