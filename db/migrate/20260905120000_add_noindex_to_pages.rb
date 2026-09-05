# frozen_string_literal: true

# A flagship page needs the same switch Article and EventType already have: a
# page can be published — reachable at its URL, linked from wherever — and still
# be one we do not want in the search index, like the preview of a page that has
# not replaced the live one yet.
class AddNoindexToPages < ActiveRecord::Migration[7.2]
  def change
    add_column :pages, :noindex, :boolean, default: false, null: false
  end
end
