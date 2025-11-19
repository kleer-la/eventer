class AddMarketingAndContentRoles < ActiveRecord::Migration[7.2]
  def up
    Role.find_or_create_by(name: 'marketing')
    Role.find_or_create_by(name: 'content')
  end

  def down
    Role.find_by(name: 'marketing')&.destroy
    Role.find_by(name: 'content')&.destroy
  end
end
