FactoryBot.define do
  factory :list do
    user
    name 'some list name'

    trait :without_name do
      name nil
    end

    trait :without_user do
      user nil
    end

    factory :list_with_items do
      transient do
        items_count 10
        regular true
      end

      trait :query_items do
        regular false
      end

      after :create do |list, options|
        factory_symbol = options.regular ? :item : :query_item
        create_list factory_symbol, options.items_count, list: list
      end
    end
  end
end
