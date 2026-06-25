# frozen_string_literal: true

# Removes the dead NPS aggregate fields and the orphan ratings table (#74,
# phase A). No code computes or reads these; website17 does not consume them.
# Per-participant promoter_score is intentionally kept (coupled with survey #73).
class RemoveNpsAggregateFields < ActiveRecord::Migration[8.1]
  def up
    remove_column :event_types, :net_promoter_score if column_exists?(:event_types, :net_promoter_score)
    remove_column :event_types, :promoter_count if column_exists?(:event_types, :promoter_count)
    remove_column :event_types, :surveyed_count if column_exists?(:event_types, :surveyed_count)

    remove_column :events, :net_promoter_score if column_exists?(:events, :net_promoter_score)

    remove_column :trainers, :net_promoter_score if column_exists?(:trainers, :net_promoter_score)
    remove_column :trainers, :promoter_count if column_exists?(:trainers, :promoter_count)
    remove_column :trainers, :surveyed_count if column_exists?(:trainers, :surveyed_count)

    drop_table :ratings if table_exists?(:ratings)
  end

  def down
    add_column :event_types, :net_promoter_score, :integer
    add_column :event_types, :promoter_count, :integer
    add_column :event_types, :surveyed_count, :integer

    add_column :events, :net_promoter_score, :integer

    add_column :trainers, :net_promoter_score, :integer
    add_column :trainers, :promoter_count, :integer
    add_column :trainers, :surveyed_count, :integer

    create_table :ratings do |t|
      t.decimal :global_event_rating, precision: 4, scale: 2
      t.integer :global_event_rating_count
      t.integer :global_nps
      t.integer :global_nps_count
      t.decimal :global_trainer_rating, precision: 4, scale: 2
      t.integer :global_trainer_rating_count
      t.integer :user_id
      t.timestamps
      t.index :user_id, name: 'index_ratings_on_user_id'
    end
  end
end
