FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password 'qwer1234'
    password_confirmation 'qwer1234'
    first_name 'John'

    trait :without_password do
      password ''
    end

    trait :without_email do
      email ''
    end

    trait :without_first_name do
      first_name ''
    end

    trait :without_password_confirmation do
      password_confirmation ''
    end

    trait :with_lists do
      transient do
        lists_count 3
      end

      after :create do |user, options|
        create_list :list, options.lists_count, user: user
      end
    end

    trait :with_groups do
      transient do
        groups_count 3
      end

      after :create do |user, transients|
        create_list(:group, transients.groups_count, creator: user, users: [user])
        user.groups.reload
      end
    end
  end
end
