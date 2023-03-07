# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Resource, type: :model do
  before(:each) do
    @resource = FactoryBot.build(:resource)
  end

  it 'create a valid instance' do
    expect(@resource.valid?).to be true
  end
end