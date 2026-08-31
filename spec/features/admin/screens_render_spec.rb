# frozen_string_literal: true

require 'rails_helper'

# Every ActiveAdmin index, visited. The News screen sat broken behind an
# action_item pointing at a route that no longer existed, and nothing noticed
# because nothing rendered these pages. This does not check what a screen shows
# — the specs next to it do that — only that it renders at all, which is the
# cheapest guard against the next dead link or renamed column.
RSpec.describe 'Admin screens', type: :feature do
  before do
    login_as(create(:administrator), scope: :user)
    FileStoreService.create_null # the Images screen would otherwise reach for S3
  end

  it 'renders every index' do
    paths = admin_index_paths
    # Guard against the enumeration quietly finding nothing and passing.
    expect(paths).to include(admin_articles_path, admin_news_index_path, admin_episodes_path)

    broken = paths.filter_map do |path|
      visit path
      "#{path} -> HTTP #{page.status_code}" unless page.status_code == 200
    rescue StandardError => e
      "#{path} -> #{e.class}: #{e.message.lines.first.to_s.strip}"
    end

    expect(broken).to be_empty, "Admin screens that do not render:\n#{broken.join("\n")}"
  end

  # ActiveAdmin loads its DSL on the first request, and the test environment does
  # not eager load, so without this the namespace is empty and the sweep passes
  # having visited nothing at all.
  def admin_index_paths
    ActiveAdmin.application.load!
    ActiveAdmin.application.namespaces[:admin].resources
               .reject { |resource| comments?(resource) }
               .select { |resource| resource.respond_to?(:route_collection_path) }
               .map(&:route_collection_path)
  end

  # ActiveAdmin registers a Comment resource in every namespace whatever
  # `config.comments` says — that setting only hides it from the menu — and this
  # app has no active_admin_comments table. So /admin/comments raises, from the
  # gem's own route, with nothing in the app linking to it. Skipped rather than
  # papered over with a table for a feature that is turned off.
  def comments?(resource)
    resource.respond_to?(:resource_class) && resource.resource_class.to_s == 'ActiveAdmin::Comment'
  end
end
