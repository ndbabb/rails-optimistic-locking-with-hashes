FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "Item #{n}" }
    person
  end
end
