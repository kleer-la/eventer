class HabmArticleTrainer < ActiveRecord::Migration[5.2]
  def change
    create_join_table :articles, :trainers do |t|
      t.index [:article_id, :trainer_id]
    end
  end
end
