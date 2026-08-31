# frozen_string_literal: true

require 'rails_helper'

# The admin screens for the models whose publication flag changed name: News and
# Service went from `visible` to `published`, and Episode gained `published`
# beside the date now called `released_at`. Nothing rendered these pages before,
# so a missed `permit_params` would have dropped the field on save in silence.
RSpec.describe 'Admin publication flags', type: :feature do
  let(:administrator) { create(:administrator) }

  before { login_as(administrator, scope: :user) }

  def submit
    find("input[type='submit']").click
  end

  describe 'news' do
    let!(:item) { create(:news, title: 'Charla en Buenos Aires', published: false) }

    it 'lists, filters and scopes by published' do
      create(:news, title: 'Ya anunciada', published: true)

      visit admin_news_index_path
      expect(page).to have_content('Charla en Buenos Aires').and have_content('Ya anunciada')

      visit admin_news_index_path(scope: 'published')
      expect(page).to have_content('Ya anunciada')
      expect(page).not_to have_content('Charla en Buenos Aires')

      visit admin_news_index_path(q: { published_eq: false })
      expect(page).to have_content('Charla en Buenos Aires')
      expect(page).not_to have_content('Ya anunciada')
    end

    it 'publishes one from the form' do
      visit edit_admin_news_path(item)
      check 'Published'
      submit

      expect(item.reload.published).to be(true)
    end
  end

  describe 'services' do
    let!(:service) { create(:service, name: 'Formación en Scrum', published: false) }

    it 'shows the flag and publishes one from the form' do
      visit admin_services_path
      expect(page).to have_content('Formación en Scrum')

      visit admin_service_path(service)
      expect(page).to have_content('Formación en Scrum')

      visit edit_admin_service_path(service)
      check 'Published'
      submit

      expect(service.reload.published).to be(true)
    end
  end

  describe 'episodes' do
    let(:podcast) { Podcast.create!(title: 'Kleer Podcast', description: '<p>x</p>') }
    let!(:episode) do
      podcast.episodes.create!(title: 'Piloto', description: '<p>x</p>', season: 1, episode: 1,
                               released_at: Date.new(2026, 8, 1), published: false)
    end

    it 'lists, filters by the flag, and renders the detail page' do
      visit admin_episodes_path
      expect(page).to have_content('Piloto')

      visit admin_episodes_path(q: { published_eq: true })
      expect(page).not_to have_content('Piloto')

      visit admin_episode_path(episode)
      expect(page).to have_content('Piloto')
    end

    it 'publishes one from the form, leaving the release date alone' do
      visit edit_admin_episode_path(episode)
      check 'Published'
      submit

      expect(episode.reload.published).to be(true)
      expect(episode.released_at).to eq(Date.new(2026, 8, 1))
    end

    it 'renders the podcast page with its episodes and the quick-add form' do
      visit admin_podcast_path(podcast)

      expect(page).to have_content('Piloto')
      expect(page).to have_content('Add New Episode')
    end
  end
end
