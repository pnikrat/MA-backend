require 'rails_helper'

RSpec.describe Item do
  let(:item) { FactoryBot.build(:item) }
  let(:item_without_name) { FactoryBot.build(:item, :without_name) }
  let(:item_without_list) { FactoryBot.build(:item, :without_list) }

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

  context 'state machine' do
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
end
