# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'articles/index', type: :view do
  before(:each) do
    assign(:articles, [
             Article.create!(
               title: 'Title 1',
               body: 'MyText',
               description: 'MyDescr',
               published: false
             ),
             Article.create!(
               title: 'Title 2',
               body: 'MyText',
               description: 'MyDescr',
               published: false
             )
           ])
  end

  it 'renders a list of articles' do
    render
    assert_select 'tr>td', text: 'Title 1'.to_s, count: 1
    assert_select 'tr>td', text: 'Title 2'.to_s, count: 1
    assert_select 'tr>td', text: 'MyDescr'.to_s, count: 2
    assert_select 'tr>td', text: false.to_s, count: 2
  end
end
