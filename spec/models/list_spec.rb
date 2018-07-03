require 'rails_helper'

RSpec.describe List do
  let(:list_without_name) { build(:list, :without_name) }
  let(:list_without_user) { build(:list, :without_user) }
  let(:list) { build(:list) }

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

  context 'scopes' do
    let(:user_groupless) { create(:user, :with_lists) }
    let(:user) { create(:user, :with_lists, :with_groups) }
    let(:members) { [create(:user), create(:user), create(:user)] }
    let(:members_with_lists) do
      [create(:user, :with_lists), create(:user, :with_lists), create(:user, :with_lists)]
    end
    let(:group_with_users) { create(:group, :with_users, user_traits: [:with_lists]) }
    let(:sub_user) { create(:user, :with_lists) }

    describe 'within_groups' do
      it 'gets all lists of user if he does not belong to any group' do
        user_groupless
        expect(described_class.user_lists(user_groupless)).to match_array user_groupless.lists
      end

      it 'gets all lists of user when belongs to group without any members' do
        user
        expect(described_class.user_lists(user)).to match_array user.lists
      end

      it 'gets all lists of user when belongs to group whose members have no lists' do
        user.groups.each_with_index do |g, i|
          g.users << members[i]
        end
        expect(User.count).to eq 4
        expect(Group.count).to eq 3
        expect(described_class.count).to eq 3
        expect(described_class.user_lists(user)).to match_array user.lists
      end

      it 'gets lists of user and members from three different groups' do
        user.groups.each_with_index do |g, i|
          g.users << members_with_lists[i]
        end
        expect(described_class.count).to eq 12 # 3 of tested user and 3 each for 3 members
        expect(described_class.user_lists(user).count).to eq 12
        expected_lists = members_with_lists.flat_map(&:lists) + user.lists
        expect(described_class.user_lists(user)).to match_array expected_lists
      end

      it 'gets lists of user and members without duplicates from several memberships' do
        user.groups.each_with_index do |g, i|
          g.users << members_with_lists[i]
          g.users << members_with_lists[i + 1] if i + 1 < 3
        end
        expected_lists = members_with_lists.flat_map(&:lists) + user.lists
        expect(described_class.user_lists(user)).to match_array expected_lists
      end

      it 'gets lists of members from group user is only a member of' do
        group_with_users.users << user
        expect(User.count).to eq 5 # creator is not member in group_with_users factory
        expect(described_class.count).to eq 12
        expected_lists = group_with_users.users.flat_map(&:lists)
        expect(described_class.user_lists(user)).to match_array expected_lists
      end

      it 'gets lists of members from group user is a member of and from users groups combined' do
        group_with_users.users << user
        user.groups.each_with_index do |g, i|
          g.users << members_with_lists[i]
        end
        expect(described_class.count).to eq 21
        expected_lists = group_with_users.users.flat_map(&:lists) +
                         members_with_lists.flat_map(&:lists)
        expect(described_class.user_lists(user)).to match_array expected_lists
      end

      it 'does not get lists of second level of groups' do
        user_with_sublevel = group_with_users.users.first
        sub_group = user_with_sublevel.groups.create(name: 'random', creator: user_with_sublevel)
        sub_group.users << sub_user
        group_with_users.users << user
        expect(described_class.count).to eq 15
        expected_lists = group_with_users.users.flat_map(&:lists)
        expect(described_class.user_lists(user)).to match_array expected_lists
        expect(described_class.user_lists(user)).not_to include(*sub_user.lists)
      end
    end
  end
end
