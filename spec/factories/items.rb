FactoryBot.define do
  factory :item do
    list
    name 'some item name'

    trait :without_name do
      name nil
    end

    trait :without_list do
      list nil
    end
  end
end
