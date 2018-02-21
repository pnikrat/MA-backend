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

    it 'transitions to to_buy from bought state after cancel_buy event' do
      expect(item).to transition_from(:bought).to(:to_buy).on_event(:cancel_buy)
    end

    it 'transitions to missing from to_buy state after not_in_shop event' do
      expect(item).to transition_from(:to_buy)
        .to(:missing).on_event(:not_in_shop)
    end
  end

  context 'state changes via params' do
    it 'changes state on proper events' do
      expect(persisted_item).to have_state(:to_buy)
      expect(persisted_item.change_state('buy')).to eq true
      expect(persisted_item).to have_state(:bought)
      persisted_item.change_state('cancel_buy')
      expect(persisted_item).to have_state(:to_buy)
      persisted_item.change_state('not_in_shop')
      expect(persisted_item).to have_state(:missing)
    end

    it 'returns false on invalid event' do
      expect(persisted_item.change_state('some_random_event')).to eq false
      expect(persisted_item.errors.full_messages.length).to eq 1
      expect(persisted_item.errors.messages[:aasm_state].first)
        .to include message: 'invalid state change'
    end
  end
end
