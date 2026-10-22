# frozen_string_literal: true

# Where a retired resource sends its traffic: the site answers its URL with a
# 301 to it, as it does for articles, services and areas (#236).
class AddRedirectUrlToResources < ActiveRecord::Migration[8.1]
  def change
    add_column :resources, :redirect_url, :string
  end
end
