class AddPublisherRole < ActiveRecord::Migration[7.2]
  def up
    Role.find_or_create_by(name: 'publisher')
  end

  def down
    Role.find_by(name: 'publisher')&.destroy
  end
end
