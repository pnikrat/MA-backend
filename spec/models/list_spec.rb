require 'rails_helper'

RSpec.describe List do
  let(:list_without_name) { FactoryBot.build(:list, :without_name) }
  let(:list_without_user) { FactoryBot.build(:list, :without_user) }
  let(:list) { FactoryBot.build(:list) }

  context 'basic model validations' do
    it 'list is not valid without name' do
      expect(list_without_name).not_to be_valid
    end

    it 'list is not valid without user' do
      expect(list_without_user).not_to be_valid
    end

    it 'list is valid with a name and user' do
      expect(list).to be_valid
    end
  end
end
