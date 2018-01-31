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
  end
end
