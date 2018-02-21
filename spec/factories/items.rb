FactoryBot.define do
  factory :item do
    list
    name 'still water'

    trait :without_name do
      name nil
    end

    trait :without_list do
      list nil
    end

    factory :full_item do
      quantity 14
      price 12.56
      unit 'bottles'
    end

    # state change factories
    factory :buy do
      state 'buy'

      trait :with_invalid_event do
        state 'some_random_event'
      end
    end
  end
end
