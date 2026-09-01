# frozen_string_literal: true

require 'rails_helper'

# What website17 reads. Episodes carry two publication states: `released_at`,
# when the episode came out on Spotify or YouTube, and `published`, whether we
# show it on our own site — only the second one decides what this endpoint
# answers with.
RSpec.describe 'API v3 podcasts', type: :request do
  let!(:podcast) { Podcast.create!(title: 'Kleer Podcast', description: '<p>Sobre agilidad</p>') }

  def episode(title, published:)
    podcast.episodes.create!(title: title, description: '<p>x</p>', season: 1, episode: rand(1..1000),
                             released_at: Date.new(2026, 8, 1), published: published)
  end

  it 'lists only the episodes published on the site' do
    episode('Al aire', published: true)
    episode('Todavía no', published: false)

    get '/api/v3/podcasts.json'

    titles = response.parsed_body.first['episodes'].pluck('title')
    expect(titles).to eq(['Al aire'])
  end

  # website17 read `published_at` until it moved to `released_at`; the alias that
  # kept answering with the old key is gone with it.
  it 'answers with released_at, and no longer with the old published_at key' do
    episode('Al aire', published: true)

    get '/api/v3/podcasts.json'

    aired = response.parsed_body.first['episodes'].first
    expect(aired['released_at']).to eq('2026-08-01')
    expect(aired).not_to have_key('published_at')
  end
end
