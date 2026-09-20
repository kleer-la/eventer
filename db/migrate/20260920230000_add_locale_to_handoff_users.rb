# frozen_string_literal: true

# The language the person requested the resource in (the site's download form,
# #203): it governs every handoff page they see and the briefing's default voice.
class AddLocaleToHandoffUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :handoff_users, :locale, :string, null: false, default: 'es'
  end
end
