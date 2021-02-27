class AddRefererCodeToParticipant < ActiveRecord::Migration
  def change
    add_column :participants, :referer_code, :string
  end
end
