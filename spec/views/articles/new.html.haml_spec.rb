# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'articles/new', type: :view do
  before(:each) do
    assign(:article, Article.new(
                       title: 'MyString',
                       tabtitle: 'MyString',
                       body: 'MyText',
                       description: 'MyDescr',
                       published: false
                     ))
  end

  it 'renders new article form' do
    render

    assert_select 'form[action=?][method=?]', articles_path, 'post' do
      assert_select 'input[name=?]', 'article[title]'

      assert_select 'input[name=?]', 'article[tabtitle]'

      assert_select 'textarea[name=?]', 'article[body]'
      assert_select 'input[name=?]', 'article[description]'
      assert_select 'input[name=?]', 'article[published]'
    end
  end
end
