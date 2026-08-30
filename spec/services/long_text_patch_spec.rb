# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LongTextPatch do
  def patch(specs, text: 'Uno dos tres', given: [])
    described_class.new(specs, patchable: %w[body notes], given: given, current: ->(_field) { text }).apply
  end

  it 'replaces the found text and reports what it did, in context' do
    result = patch([{ field: 'body', find: 'dos', replace: 'DOS' }])

    expect(result.errors).to be_empty
    expect(result.fields).to eq('body' => 'Uno DOS tres')
    expect(result.applied['body']).to eq([{ find: 'dos', replace: 'DOS', occurrences: 1, context: 'Uno DOS tres' }])
  end

  it 'chains replacements on the same field, each against what the previous one left' do
    result = patch([{ field: 'body', find: 'dos', replace: 'DOS' },
                    { field: 'body', find: 'Uno DOS', replace: 'uno dos' }])

    expect(result.fields['body']).to eq('uno dos tres')
    expect(result.applied['body'].size).to eq(2)
  end

  it 'takes the replacement literally, so a backreference is not expanded' do
    expect(patch([{ field: 'body', find: 'dos', replace: '\1 y \\' }]).fields['body']).to eq('Uno \1 y \\ tres')
  end

  it 'deletes the found text when no replacement is given' do
    expect(patch([{ field: 'body', find: ' dos' }]).fields['body']).to eq('Uno tres')
  end

  it 'accepts the string keys that reach a tool inside an array argument' do
    result = patch([{ 'field' => 'body', 'find' => 'dos', 'replace' => 'DOS' }])

    expect(result.fields['body']).to eq('Uno DOS tres')
  end

  it 'trims the context to what surrounds the edit' do
    long = "#{'a' * 300}necesita#{'b' * 300}"
    context = patch([{ field: 'body', find: 'necesita', replace: 'usa' }], text: long).applied['body'].first[:context]

    expect(context).to eq("…#{'a' * described_class::CONTEXT}usa#{'b' * described_class::CONTEXT}…")
  end

  it 'refuses an unpatchable field, naming the ones that take a patch' do
    result = patch([{ field: 'title', find: 'dos', replace: 'DOS' }])

    expect(result.errors.join).to include('title').and include('body, notes')
    expect(result.fields).to be_empty
  end

  it 'refuses a find that matches nothing, quoting it' do
    expect(patch([{ field: 'body', find: 'cuatro', replace: 'x' }]).errors.join).to include('"cuatro"')
  end

  it 'refuses an ambiguous find, and replaces every occurrence when asked to' do
    ambiguous = { field: 'body', find: 'o', replace: '0' }

    expect(patch([ambiguous], text: 'Uno dos').errors.join).to include('2 times')
    expect(patch([ambiguous.merge(all: true)], text: 'Uno dos').fields['body']).to eq('Un0 d0s')
  end

  it 'refuses a field the caller is also sending whole' do
    expect(patch([{ field: 'body', find: 'dos', replace: 'x' }], given: %w[body]).errors.join).to match(/both/i)
  end
end
