# frozen_string_literal: true

require 'rails_helper'

describe ApplicationMailer do
  ['hola', 'Peter', 'Bruce Lee'].each do |name|
    it "#{name} is a valid name" do
       expect(ApplicationMailer.valid_name?(name)).to be true
    end
  end
  [ ['', 'empty'],
    ['skyreveryLiz', 'uppercase not first char'],
    ["HeyaMr...: ) the passive income it's 999eu a day C'mon -", 'too long'],
  ].each do |ex|
    it "name <#{ex[0]}> is invalid. Reason: #{ex[1]} " do
       expect(ApplicationMailer.valid_name?(ex[0])).to be false
    end
  end
end