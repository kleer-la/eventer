# frozen_string_literal: true

require 'rails_helper'

# An MCP caller names a service area by id, slug or name. Names repeat across
# languages, so a name may resolve to several areas.
RSpec.describe ServiceArea, '.referenced_by' do
  let!(:es) { FactoryBot.create(:service_area, name: 'Agile Product Management', slug: 'apm', lang: :es) }
  let!(:en) { FactoryBot.create(:service_area, name: 'Agile Product Management', slug: 'apm-en', lang: :en) }

  it 'finds one area by numeric id or by slug' do
    expect(described_class.referenced_by(es.id.to_s)).to eq [es]
    expect(described_class.referenced_by(' apm-en ')).to eq [en]
  end

  it 'returns every area that carries a name' do
    expect(described_class.referenced_by('Agile Product Management')).to contain_exactly(es, en)
    expect(described_class.referenced_by('No existe')).to be_empty
  end

  it 'describes an area so that a caller can tell the languages apart' do
    expect(en.reference).to eq "Agile Product Management (id #{en.id}, slug apm-en, lang en)"
  end
end
