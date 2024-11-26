class AddLangToMailTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :mail_templates, :lang, :integer, default: 0, null: false
  end
end
