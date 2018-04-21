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
      end

      after :create do |list, options|
        create_list :item, options.items_count, list: list
      end
    end
  end
end
