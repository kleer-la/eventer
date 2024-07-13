# frozen_string_literal: true

require 'rails_helper'

describe 'event_types/show' do
  before(:each) do
    @event_type = assign(:event_type,
                         FactoryBot.create(:event_type,
                                           name: 'ET Name',
                                           description: 'ET Descripcion',
                                           recipients: 'ET Recipients',
                                           program: 'ET Program'))
  end

  it 'show attributes ' do
    render
    expect(rendered).to match(/ET Name/)
    expect(rendered).to match(/ET Descripcion/)
    expect(rendered).to match(/ET Recipients/)
    expect(rendered).to match(/ET Program/)
  end
  it 'has a canonical' do
    other_et = FactoryBot.create(:event_type, name: 'this is da canonical')
    @event_type.canonical = other_et

    render
    expect(rendered).to match(/this is da canonical/)
  end
  it 'has clons' do
    FactoryBot.create(:event_type, name: 'yes, master!', canonical: @event_type)
    @event_type.reload # needed to populate clons

    render
    expect(rendered).to match(/yes, master!/)
  end
end
