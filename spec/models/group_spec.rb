require 'rails_helper'

RSpec.describe Group do
  let(:group) { build(:group) }
  let(:group_no_name) { build(:group, :without_name) }
  let(:group_no_creator) { build(:group, :without_creator) }
  let(:group_with_users) { create(:group, :with_users) }
  let(:user_with_groups) { create(:user, :with_groups) }
  let(:user) { create(:user) }
  let(:user_attr) { attributes_for(:user) }

  context 'basic model validations' do
    it 'group with name and creator is valid' do
      expect(group).to be_valid
    end

    it 'group without name is invalid' do
      expect(group_no_name).not_to be_valid
    end

    it 'group without creator is invalid' do
      expect(group_no_creator).not_to be_valid
    end

    it 'group with too long name is invalid' do
      group.name = 'w' * 61
      expect(group).not_to be_valid
    end

    it 'group with the same name and creator is invalid' do
      group.save
      creator = group.creator
      expect(creator.groups.create(creator: creator, name: group.name)).not_to be_valid
    end

    it 'group with different name and same creator is valid' do
      group.save
      creator = group.creator
      expect(creator.groups.create(creator: creator, name: 'random')).to be_valid
    end
  end

  context 'has many through interactions' do
    it 'group can have many users' do
      expect(group_with_users.users.length).to eq 3
    end

    it 'group with users creates necessary group memberships' do
      expect {
        group_with_users
      }.to change(GroupMembership, :count).by 3
    end

    it 'group with users can get new existing user' do
      group_with_users.users << user
      expect(group_with_users.users.length).to eq 4
      expect(GroupMembership.count).to eq 4
    end

    it 'group with users can create new user' do
      group_with_users.users.create(user_attr)
      expect(group_with_users.users.length).to eq 4
      expect(GroupMembership.count).to eq 4
    end

    it 'does not accept the same user into collection' do
      existing_user = group_with_users.users.last
      expect {
        group_with_users.users << existing_user
      }.to raise_error ActiveRecord::RecordInvalid
      expect(GroupMembership.count).to eq 3
      expect(group_with_users.reload.users.length).to eq 3
    end
  end

  context 'scopes' do
    describe 'with_member' do
      it 'returns all groups user is member of' do
        user_with_groups
        expect(described_class.with_member(user_with_groups)).to eq user_with_groups.groups
      end

      it 'returns single group user is member of' do
        member = group_with_users.users.first
        expect(described_class.with_member(member)).to eq [group_with_users]
      end

      it 'returns no groups if user is not a member of any' do
        user
        expect(described_class.with_member(user)).to be_empty
      end
    end
  end
end
