# Shopping item model
class Item < ApplicationRecord
  include AASM
  include PgSearch
  pg_search_scope :search_by_name, against: :name, using: { tsearch: { prefix: true } }
  scope :deleted, -> { where(aasm_state: 'deleted') }

  STATE_EVENT = {
    to_buy: %i[undo revive_item],
    missing: %i[not_in_shop],
    bought: %i[buy],
    deleted: %i[delete_item]
  }.freeze

  validates :name, presence: true, length: { maximum: 60 }
  validates :name, uniqueness: { scope: :list_id, case_sensitive: false }

  belongs_to :list

  attr_accessor :state

  before_update :check_state_transition

  aasm do
    state :to_buy, initial: true
    state :bought, :missing, :deleted

    event :buy do
      transitions from: :to_buy, to: :bought
    end

    event :not_in_shop do
      transitions from: :to_buy, to: :missing
    end

    event :undo do
      transitions from: %i[bought missing], to: :to_buy
    end

    event :delete_item do
      transitions to: :deleted
    end

    event :revive_item do
      transitions from: :deleted, to: :to_buy
    end
  end

  def self.search(query)
    deleted.search_by_name(query)
  end

  private

  def check_state_transition
    return if aasm_state_changed? || state.blank?
    self.state = state.to_sym
    if permissible_destination_states.include?(state) && STATE_EVENT.keys.include?(state)
      available_transitions = permissible_events & STATE_EVENT[state]
      throw_invalid_state if available_transitions.empty?
      aasm.fire(available_transitions.first)
    else
      throw_invalid_state
    end
  end

  def throw_invalid_state
    errors.add(:aasm_state, 'invalid state change')
    throw :abort
  end

  def permissible_events
    aasm.events.map(&:name)
  end

  def permissible_destination_states
    aasm.states(permitted: true).map(&:name)
  end
end
