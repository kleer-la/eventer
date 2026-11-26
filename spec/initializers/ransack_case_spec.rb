# frozen_string_literal: true

require 'rails_helper'

# ransack 4 searched cont/start/end with ILIKE on PostgreSQL; 6.x made them
# case-sensitive (LIKE) and added i_cont & co. for the old behaviour, so in QA
# and production every admin text filter stopped finding "Argentina" for "arg"
# (#241). SQLite's LIKE ignores case either way, so this checks the Arel node
# ransack builds: case_sensitive false is what PostgreSQL turns into ILIKE.
RSpec.describe 'ransack text predicates' do
  %w[cont not_cont start not_start end not_end].each do |predicate|
    it "#{predicate} ignores case, as it did before ransack 6" do
      condition = Country.ransack("name_#{predicate}" => 'arg').base.conditions.first

      expect(condition.arel_predicate.case_sensitive).to be(false)
    end
  end

  it 'still escapes LIKE wildcards' do
    sql = Country.ransack(name_cont: '50%').result.to_sql

    expect(sql).to include('50\\%')
  end
end
