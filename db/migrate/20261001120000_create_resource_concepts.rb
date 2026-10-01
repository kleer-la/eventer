# frozen_string_literal: true

# The cards of a "concepts" resource: a glossary read as a map of stages, one
# card (and one URL on the site) per concept. One row per language, since the
# English cards needn't mirror the Spanish ones.
class CreateResourceConcepts < ActiveRecord::Migration[8.1]
  def change
    create_table :resource_concepts do |t|
      t.references :resource, null: false, foreign_key: true
      t.string :lang, null: false, default: 'es'
      t.integer :position, null: false, default: 0
      t.string :slug, null: false
      t.string :name, null: false
      t.string :question
      t.string :stage, null: false
      t.text :definition
      t.text :analogy
      t.text :misconception
      t.text :correction
      t.text :practice
      t.text :media
      t.string :related_slugs
      t.timestamps
    end
    add_index :resource_concepts, %i[resource_id lang slug], unique: true
  end
end
