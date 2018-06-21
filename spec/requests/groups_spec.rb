require 'rails_helper'

RSpec.describe 'Groups api interactions' do
  let(:user) { create(:user) }
  let(:user_with_groups) { create(:user, :with_groups) }
  let(:group_with_users) { create(:group, :with_users) }

  context 'Groups#index GET' do
    it 'gets all user groups if user (as creator) is signed in and responds 200 OK' do
      get groups_path, headers: headers(user_with_groups)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 3
      expect(json[0]).to include name: 'group_1'
      expect(json[0][:creator_id]).to eq user_with_groups.id
    end

    it 'returns empty array when user has no groups and responds 200 OK' do
      get groups_path, headers: headers(user)
      expect(response).to have_http_status :ok
      expect(json).to eq []
    end

    it 'gets groups user belongs to (as member) when signed in and responds 200 OK' do
      member = group_with_users.users.last
      second_group = user_with_groups.groups.last
      second_group.users << member
      get groups_path, headers: headers(member)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 2
      expect(json.pluck(:id)).to eq [group_with_users.id, second_group.id]
    end

    it 'responds unauthorized when no tokens are passed' do
      get groups_path, headers: headers
      expect(response).to have_http_status :unauthorized
    end
  end

  context 'Groups#show GET' do
    it 'gets specific group with its members if user is signed in and responds 200 OK' do
      member = group_with_users.users.last
      get group_path(group_with_users), headers: headers(member)
      expect(response).to have_http_status :ok
      expect(json.pluck(:id)).to eq [group_with_users.id]
      expect(json[0][:users].pluck(:id)).to eq group_with_users.users.pluck(:id)
    end

    it 'does not get the group if user is not its member and responds 204 No content' do
      get group_path(group_with_users), headers: headers(user_with_groups)
      expect(response).to have_http_status :no_content
    end

    it 'responds unauthorized when no tokens passed' do
      get group_path(group_with_users), headers: headers
      expect(response).to have_http_status :unauthorized
    end
  end
end
