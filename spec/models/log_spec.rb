# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Log, type: :model do
  it { expect { Log.log(:xero, :info, '') }.to change { Log.count }.by(1) }
end
