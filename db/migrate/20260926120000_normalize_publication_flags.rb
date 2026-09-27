# frozen_string_literal: true

# "Is this on the site?" had three answers with defaults that disagreed: a news
# was born published while an article was born hidden, and resources,
# categories and service areas could hold NULL, a third state the code never
# meant. Every publication flag is now born false and never NULL. Every reader
# asks `where(flag: true)`, so a NULL was already hidden: backfilling it to
# false changes nothing on the site (kleer-la/eventer#195).
class NormalizePublicationFlags < ActiveRecord::Migration[7.2]
  FLAGS = { articles: :published, resources: :published, categories: :visible, service_areas: :visible }.freeze

  def up
    FLAGS.each do |table, flag|
      change_column_default table, flag, from: nil, to: false unless table == :articles
      change_column_null table, flag, false, false
    end
    change_column_default :news, :published, from: true, to: false
  end

  def down
    change_column_default :news, :published, from: false, to: true
    FLAGS.each do |table, flag|
      change_column_null table, flag, true
      change_column_default table, flag, from: false, to: nil unless table == :articles
    end
  end
end
