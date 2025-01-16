FactoryBot.define do
  factory :trainer do
    name { 'Juan Alberto' }
    signature_image { 'PT.png' }
    signature_credentials { 'Agile Coach & Trainer' }
    # sequence(:name) { |n| n == 1 ? 'Juan Alberto' : "Juan Alberto #{n}" }
    # sequence(:signature_image) { |n| n == 1 ? 'PT.png' : "PT#{n}.png" }
    # sequence(:signature_credentials) { |n| n == 1 ? 'Agile Coach & Trainer' : "Agile Coach & Trainer #{n}" }
  end

  factory :trainer2, class: Trainer do
    name { 'Juan Torto' }
    signature_image { 'JG.png' }
    signature_credentials { 'Agile Coach & Trainer2' }
  end
end
