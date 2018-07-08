require 'rails_helper'

RSpec.describe 'Group invitation creation' do
  let(:user) { create(:user, :with_groups) }
  let(:group) { user.groups.first }
  let(:user2) { create(:user) }
  let(:invite_params) { attributes_for(:invite, invitable_id: group.id) }

  context 'Invites#create POST' do
    it 'Raises proper error when user is not authenticated' do
      expect {
        post invites_path, params: invite_params.to_json, headers: headers
      }.not_to change(Invite, :count)
      expect(response).to have_http_status :unauthorized
    end

    it 'Raises proper error when user is authenticated but not authorized to invite' do
      expect {
        post invites_path, params: invite_params.to_json, headers: headers(user2)
      }.not_to change(Invite, :count)
      expect(response).to have_http_status :unauthorized
      expect(json[:status]).to eq 'failed'
      expect(json[:errors]).to eq 'unauthorized access'
    end

    it 'creates an invite when user is authenticated and authorized to sending invites' do
      expect {
        post invites_path, params: invite_params.to_json, headers: headers(user)
      }.to change(Invite, :count).by 1
      expect(response).to have_http_status :created
      expect(json[:email]).to eq invite_params[:email]
      expect(json[:invitable_id]).to eq group.id
      expect(json[:sender_id]).to eq user.id
    end
  end
end
