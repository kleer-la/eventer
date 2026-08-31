# frozen_string_literal: true

# News and Service spelled their publication flag `visible`, while Article and
# Resource spelled the same idea `published`. Worse, `visible` already means
# something else here: Event.visible is "not cancelled and not long past".
#
# The public API keeps answering with a `visible` key for news until website17
# reads the new one — see News#visible.
class RenameVisibleToPublishedOnNewsAndServices < ActiveRecord::Migration[8.1]
  def change
    rename_column :news, :visible, :published
    rename_column :services, :visible, :published
  end
end
