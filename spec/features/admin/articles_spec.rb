# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin Articles', type: :feature do
  let(:administrator) { create(:administrator) }

  before do
    login_as(administrator, scope: :user)
  end

  describe 'index page' do
    it 'lists all articles' do
      article1 = create(:article, title: 'First Article', published: true)
      article2 = create(:article, title: 'Second Article')

      visit admin_articles_path

      expect(page).to have_content('Articles')
      expect(page).to have_content(article1.title)
      expect(page).not_to have_content(article2.title)
    end
  end

  describe 'show page' do
    it 'displays article details' do
      article = create(:article, title: 'Test Article', description: 'Test Description')

      visit admin_article_path(article)

      expect(page).to have_content(article.title)
      expect(page).to have_content(article.description)
    end
  end

  describe 'new/create' do
    it 'allows creating a new article' do
      visit new_admin_article_path

      fill_in 'Title', with: 'New Article'
      fill_in 'Description', with: 'New Description'
      choose 'En'
      check 'Published'
      fill_in 'Body', with: 'Article content'

      click_button 'Crear'

      # expect(page).to have_content("Article was successfully created")
      expect(page).to have_content('New Article')
    end
  end

  describe 'edit/update' do
    it 'allows updating an existing article' do
      article = create(:article, title: 'Old Title')

      visit edit_admin_article_path(article)

      fill_in 'Title', with: 'Updated Title'
      click_button 'Guardar Cambios'

      # expect(page).to have_content("Updated ")
      expect(page).to have_content('Updated Title')
    end
  end

  describe 'recommended content' do
    it 'displays recommended content' do
      article = create(:article)
      recommended_article = create(:article, title: 'Recommended Article')
      create(:recommended_content, source: article, target: recommended_article)

      visit admin_article_path(article)

      expect(page).to have_content('Recommended Content')
      expect(page).to have_content(recommended_article.title)
    end
  end
end
