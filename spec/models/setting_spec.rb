# frozen_string_literal: true

require 'rails_helper'

describe Setting do
  it 'existing setting' do
    FactoryBot.create(:setting)

    expect(Setting.get('Hi')).to eq 'Hello'
  end

  it 'setting not found' do
    expect(Setting.get('Hi')).to eq ''
  end
end
