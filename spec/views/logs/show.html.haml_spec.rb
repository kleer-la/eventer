require 'rails_helper'

RSpec.describe 'logs/show.html.haml', type: :view do
  it 'renders attributes in <p>' do
    assign(:log, Log.create!(
                   area: :app,
                   level: :warn,
                   message: 'One Message',
                   details: 'Detailed description'
                 ))
    render
    expect(rendered).to match(/app/)
    expect(rendered).to match(/warn/)
    expect(rendered).to match(/One Message/)
    expect(rendered).to match(/Detailed description/)
  end
end
