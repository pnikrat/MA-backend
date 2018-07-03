require 'rails_helper'

RSpec.describe ListChannel, type: :channel do
  let(:user) { create(:user, :with_lists, :with_groups) }
  let(:user_member) { create(:user, :with_lists) }

  before :each do
    stub_connection current_user: user
  end

  it 'subscribes to list belonging to user' do
    subscribe(list_id: user.lists.first.id)
    expect(subscription).to be_confirmed
    expect(streams.length).to eq 1
  end

  it 'subscribes to list belonging to member of user group' do
    user.groups.first.users << user_member
    subscribe(list_id: user_member.lists.first.id)
    expect(subscription).to be_confirmed
    expect(streams.length).to eq 1
  end

  it 'rejects subscription when no list id is provided' do
    subscribe
    expect(subscription).to be_rejected
  end

  it 'rejects subscription when user has no access to list' do
    subscribe(list_id: user_member.lists.first.id)
    expect(subscription).to be_rejected
  end
end
