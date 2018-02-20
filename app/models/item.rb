# Shopping item model
class Item < ApplicationRecord
  include AASM

  validates :name, presence: true, length: { maximum: 60 }

  belongs_to :list

  aasm do
    state :to_buy, initial: true
    state :bought, :missing

    event :buy do
      transitions from: :to_buy, to: :bought
    end

    event :cancel_buy do
      transitions from: :bought, to: :to_buy
    end

    event :not_in_shop do
      transitions from: :to_buy, to: :missing
    end
  end
end
