# frozen_string_literal: true

require 'rails_helper'

# What MCP list tools filter `query` with. SQLite matches ASCII case-insensitively
# on its own; PostgreSQL (QA and production) does not, which is how a title with a
# capital letter went unfound by a lowercase search.
describe ApplicationRecord do
  describe '.matching' do
    let!(:strategy) { create(:article, title: 'Estrategia de Producto', slug: 'estrategia-de-producto') }
    let!(:other) { create(:article, title: 'Otro tema', slug: 'otro-tema-100') }

    it 'finds a substring whatever its case' do
      expect(Article.matching('estrategia DE producto', :title)).to contain_exactly(strategy)
    end

    it 'looks in every column given' do
      expect(Article.matching('tema-100', :title, :slug)).to contain_exactly(other)
    end

    it 'takes % and _ as plain characters, not wildcards' do
      expect(Article.matching('%', :title)).to be_empty
      expect(Article.matching('Otro_tema', :title)).to be_empty
    end

    it 'escapes the wildcards, so the database reads them as plain characters' do
      expect(Article.matching('x', :title).to_sql).to include('ESCAPE')
    end

    it 'accepts a column of another table, for a joined scope' do
      event_type = create(:event_type, name: 'Taller Scrum')
      event = create(:event, event_type: event_type)

      found = Event.joins(:event_type).matching('SCRUM', EventType.arel_table[:name], :city)

      expect(found).to contain_exactly(event)
    end
  end
end
