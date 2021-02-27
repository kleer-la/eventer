class AddRefererCodeToParticipant < ActiveRecord::Migration[5.0]
  def change
    add_column :participants, :referer_code, :string
  end
end
