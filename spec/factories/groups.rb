FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "group_#{n}" }
    creator factory: :user

    trait :without_name do
      name nil
    end

    trait :without_creator do
      creator nil
    end

    trait :with_users do
      transient do
        user_count 3
        user_traits []
      end

      after :create do |group, transients|
        create_list(:user, transients.user_count, *transients.user_traits, groups: [group])
        group.users.reload
      end
    end
  end
end
