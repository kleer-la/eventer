# frozen_string_literal: true

class AddCancellationPolicyToEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :event_types, :cancellation_policy, :text
    add_column :events, :cancellation_policy, :text
  end
end
