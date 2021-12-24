require 'rails_helper'

RSpec.describe 'articles/edit', type: :view do
  before(:each) do
    @article = assign(:article, Article.create!(
      title: 'MyString',
      tabtitle: 'MyTab',
      body: 'MyText',
      description: 'MyText',
      published: false
    ))
  end

  it 'renders the edit article form' do
    render

    assert_select 'form[action=?][method=?]', article_path(@article), 'post' do

      assert_select 'input[name=?]', 'article[title]'
      assert_select 'input[name=?]', 'article[tabtitle]'
      assert_select 'textarea[name=?]', 'article[body]'
      assert_select 'input[name=?]', 'article[description]'
      assert_select 'input[name=?]', 'article[published]'
    end
  end
  
  it 'show authors (trainers)' do
    FactoryBot.create(:trainer, name: 'Luke Skywalker')
    FactoryBot.create(:trainer, name: 'Obi Wan Kenobi')
    render
    expect(rendered).to match(/Luke Skywalker/)
    expect(rendered).to match(/Obi Wan Kenobi/)
    assert_select 'input[name=?]', 'article[trainer_ids][]'
    # assert_select 'select[name=?]', 'article[trainer_ids][]'
  end

end
