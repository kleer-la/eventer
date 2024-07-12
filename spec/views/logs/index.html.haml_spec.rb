require 'rails_helper'

RSpec.describe 'logs/index.html.haml', type: :view do
  it 'renders a list of articles' do
    Log.destroy_all
    Log.log(:xero, :error, 'Message 1')
    Log.log(:xero, :info, 'Message 2')
    assign(:logs, Log.all)
    render
    assert_select 'tr>td', text: 'Message 1'.to_s, count: 1
    assert_select 'tr>td', text: 'Message 2'.to_s, count: 1
    assert_select 'tr>td', text: 'xero'.to_s, count: 2
  end
end
