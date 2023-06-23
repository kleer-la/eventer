class CreateJoinTableNewsTrainers < ActiveRecord::Migration[7.0]
  def change
    create_join_table :news, :trainers do |t|
      t.index [:news_id, :trainer_id]
      t.index [:trainer_id, :news_id]
    end
  end
end