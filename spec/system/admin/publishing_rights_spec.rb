# frozen_string_literal: true

require 'rails_helper'

# The admin forms draw the same line for every published thing: a content user
# sees the flag but cannot flip it, a publisher can (kleer-la/eventer#195).
RSpec.describe 'Admin publishing rights', type: :system do
  include Devise::Test::IntegrationHelpers

  before { driven_by(:rack_test) }

  let!(:news) { create(:news, published: false) }
  let!(:episode) do
    podcast = Podcast.create!(title: 'Kleer Podcast', description: '<p>x</p>')
    podcast.episodes.create!(title: 'Piloto', description: '<p>x</p>', season: 1, episode: 1,
                             released_at: Date.new(2026, 9, 1))
  end

  it 'keeps a content user from publishing news or episodes' do
    sign_in create(:content_user)

    visit edit_admin_news_path(news)
    expect(page).to have_field('news_published', disabled: true)

    visit edit_admin_episode_path(episode)
    expect(page).to have_field('episode_published', disabled: true)
  end

  it 'lets a publisher publish news and episodes' do
    sign_in create(:publisher_user)

    visit edit_admin_news_path(news)
    expect(page).to have_field('news_published', disabled: false)

    visit edit_admin_episode_path(episode)
    expect(page).to have_field('episode_published', disabled: false)
  end
end
