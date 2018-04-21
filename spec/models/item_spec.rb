require 'rails_helper'

RSpec.describe Item do
  let(:item) { FactoryBot.build(:item) }
  let(:item_without_name) { FactoryBot.build(:item, :without_name) }
  let(:item_without_list) { FactoryBot.build(:item, :without_list) }
  let(:persisted_item) { FactoryBot.create(:item) }

  context 'basic model validations' do
    it 'is valid with list and name' do
      expect(item).to be_valid
    end

    it 'is not valid without name' do
      expect(item_without_name).not_to be_valid
    end

    it 'is not valid without list' do
      expect(item_without_list).not_to be_valid
    end
  end

  context 'state machine mocks' do
    it 'is initially in to_buy state' do
      expect(item).to have_state :to_buy
    end

    it 'transitions to bought from to_buy state after buy event' do
      expect(item).to transition_from(:to_buy).to(:bought).on_event(:buy)
    end

    it 'transitions to to_buy from bought or missing state after undo event' do
      expect(item).to transition_from(:bought).to(:to_buy).on_event(:undo)
      expect(item).to transition_from(:missing).to(:to_buy).on_event(:undo)
    end

    it 'transitions to missing from to_buy state after not_in_shop event' do
      expect(item).to transition_from(:to_buy).to(:missing).on_event(:not_in_shop)
    end

    it 'transitions to deleted from any state after delete_item event' do
      expect(item).to transition_from(:to_buy).to(:deleted).on_event(:delete_item)
      expect(item).to transition_from(:bought).to(:deleted).on_event(:delete_item)
      expect(item).to transition_from(:missing).to(:deleted).on_event(:delete_item)
    end

    it 'transitions to to_buy from deleted state after revive_item event' do
      expect(item).to transition_from(:deleted).to(:to_buy).on_event(:revive_item)
    end
  end

  context 'state changes via before_update callback' do
    it 'changes state when passing desired destination state' do
      expect(persisted_item).to have_state(:to_buy)
      persisted_item.state = 'bought'
      persisted_item.save
      expect(persisted_item).to have_state(:bought)

      persisted_item.state = 'to_buy'
      persisted_item.save
      expect(persisted_item).to have_state(:to_buy)

      persisted_item.state = 'missing'
      persisted_item.save
      expect(persisted_item).to have_state(:missing)

      persisted_item.state = 'to_buy'
      persisted_item.save
      expect(persisted_item).to have_state(:to_buy)

      persisted_item.state = 'deleted'
      persisted_item.save
      expect(persisted_item).to have_state(:deleted)

      persisted_item.state = 'to_buy'
      persisted_item.save
      expect(persisted_item).to have_state(:to_buy)

      persisted_item.state = 'missing'
      persisted_item.save
      persisted_item.state = 'deleted'
      persisted_item.save
      expect(persisted_item).to have_state(:deleted)

      persisted_item.state = 'to_buy'
      persisted_item.save
      persisted_item.state = 'bought'
      persisted_item.save
      persisted_item.state = 'deleted'
      persisted_item.save
      expect(persisted_item).to have_state(:deleted)
    end

    it 'fails to change state on invalid desired state name. Adds proper error' do
      expect {
        persisted_item.state = 'some_random_state'
        persisted_item.save
      }.not_to(change { persisted_item.aasm_state })
      expect(persisted_item.errors.full_messages.length).to eq 1
      expect(persisted_item.errors[:aasm_state].first)
        .to include 'invalid state change'
    end

    it 'fails to change state on invalid transition' do
      expect(persisted_item).to have_state(:to_buy)
      persisted_item.state = 'deleted'
      persisted_item.save
      persisted_item.state = 'bought'
      persisted_item.save
      expect(persisted_item).not_to have_state(:bought)
      expect(persisted_item).to have_state(:deleted)
    end
  end
end
