# frozen_string_literal: true

# Marketing merges articles that compete for the same search and retires the
# ones nobody reads towards their area page. Both need the old URL to answer
# 301 to another page. friendly_id's history only sends an old slug back to the
# same article, so until now every such redirect was a line in website17's
# PERMANENT_REDIRECT and a deploy. The article now names where it went
# (kleer-la/eventer#212); the site reads it even when the article is
# unpublished, so unpublishing removes it from the listing without losing
# the traffic (kleer-la/website17#429).
class AddRedirectUrlToArticles < ActiveRecord::Migration[7.2]
  def change
    add_column :articles, :redirect_url, :string
  end
end
