require 'rails_helper'

RSpec.describe User do
  let(:user) { build(:user) }
  let(:user_without_password) { build(:user, :without_password) }
  let(:user_without_email) { build(:user, :without_email) }
  let(:user_without_first_name) { build(:user, :without_first_name) }
  let(:user_with_groups) { create(:user, :with_groups) }
  let(:group) { create(:group) }
  let(:group_attr) { attributes_for(:group, creator_id: user_with_groups.id) }

  context 'basic model validations' do
    it 'user with email, password and first_name is valid' do
      expect(user).to be_valid
    end

    it 'user without password is invalid' do
      expect(user_without_password).not_to be_valid
    end

    it 'user without email is invalid' do
      expect(user_without_email).not_to be_valid
    end

    it 'user without first_name is invalid' do
      expect(user_without_first_name).not_to be_valid
    end
  end

  context 'has many through associations' do
    it 'user can create many groups' do
      expect(user_with_groups.groups.length).to eq 3
    end

    it 'user with groups creates necessary group memberships' do
      expect {
        user_with_groups
      }.to change(GroupMembership, :count).by 3
    end

    it 'user with groups can get new existing group' do
      user_with_groups.groups << group
      expect(user_with_groups.groups.length).to eq 4
      expect(GroupMembership.count).to eq 4
    end

    it 'user with groups can create new group' do
      user_with_groups.groups.create(group_attr)
      expect(user_with_groups.groups.length).to eq 4
      expect(GroupMembership.count).to eq 4
    end

    it 'does not accept the same group into collection' do
      existing_group = user_with_groups.groups.first
      expect {
        user_with_groups.groups << existing_group
      }.to raise_error ActiveRecord::RecordInvalid
      expect(GroupMembership.count).to eq 3
      expect(user_with_groups.groups.reload.length).to eq 3
    end
  end
end
