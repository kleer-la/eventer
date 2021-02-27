class AddCancellationPolicyToEvents < ActiveRecord::Migration
  def change
    add_column :event_types, :cancellation_policy, :text
    add_column :events, :cancellation_policy, :text
  end
end
