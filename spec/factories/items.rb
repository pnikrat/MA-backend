FactoryBot.define do
  factory :item do
    list
    sequence(:name) { |n| "still water #{n}" }

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

    factory :state_change do
      transient do
        desired_state 'bought'
      end

      state { desired_state }

      trait :with_invalid_event do
        state 'some_random_event'
      end

      trait :with_other_changes do
        quantity 10
        unit 'pieces'
      end
    end

    factory :query_item do
      transient do
        available_names %w[coconut chocolate apple beer bread cookie aperol brocolli potatoes wine]
      end

      sequence(:name) { |n| available_names[n % 10 - 1] || "still water #{n}" }
      sequence(:aasm_state) { |n| n.even? ? :to_buy : :deleted }
    end
  end
end
