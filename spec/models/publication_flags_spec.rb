# frozen_string_literal: true

require 'rails_helper'

# "Is this on the site?" is one question wherever it is asked: a record is born
# hidden, and the flag is never NULL, so `published == false` and `!published?`
# agree (kleer-la/eventer#195).
RSpec.describe 'publication flags' do
  {
    Article => :published, Resource => :published, News => :published, Episode => :published,
    Service => :published, Category => :visible, ServiceArea => :visible
  }.each do |model, flag|
    it "#{model} is born hidden and its #{flag} is never NULL" do
      column = model.columns_hash[flag.to_s]
      expect(column.null).to be(false)
      expect(model.new.public_send(flag)).to be(false)
    end
  end
end
