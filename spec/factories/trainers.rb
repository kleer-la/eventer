FactoryBot.define do
  factory :trainer do
    name { 'Juan Alberto' }
    signature_image { 'PT.png' }
    signature_credentials { 'Agile Coach & Trainer' }
  end

  factory :trainer2, class: Trainer do
    name { 'Juan Torto' }
    signature_image { 'JG.png' }
    signature_credentials { 'Agile Coach & Trainer2' }
  end
end
