FactoryBot.define do
  factory :invite do
    email 'mock@example.com'
    invitable_id 1
    invitable_type 'Group'
  end
end
