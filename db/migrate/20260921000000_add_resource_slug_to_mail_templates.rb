# frozen_string_literal: true

# A download-form template may belong to one resource: when a resource has
# templates of its own, they replace the generic ones for its downloads (#203,
# the session-handoff resource sends an access link, not a file).
class AddResourceSlugToMailTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :mail_templates, :resource_slug, :string
    add_index :mail_templates, :resource_slug
  end
end
