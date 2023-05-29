class UpdateArticleSlugs < ActiveRecord::Migration[7.0]
  def change
    Article.find_each do |article|
      slug = article.slug
      article.slug = nil
      article.save
      article.slug = slug
      article.save
    end
  end
end
