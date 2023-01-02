# frozen_string_literal: true

class OldMigrations < ActiveRecord::Migration[5.2]
  REQUIRED_VERSION = 20190521141710
  def up
    if ActiveRecord::Migrator.current_version < REQUIRED_VERSION
      raise StandardError, "`rails db:schema:load` must be run prior to `rails db:migrate`"
    end
  end
end