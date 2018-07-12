require 'rails_helper'

RSpec.describe 'Group invitation creation' do
  let(:user) { create(:user, :with_groups) }
  let(:group) { user.groups.first }
  let(:user2) { create(:user) }
  let(:invite_params) { attributes_for(:invite, invitable_id: group.id) }
  let(:existing_invite_params) { invite_params.merge(email: user2.email) }
  let(:invalid_invite_params) { attributes_for(:invite, :invalid, invitable_id: group.id) }
  let(:deliveries) { ActionMailer::Base.deliveries }

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

    it 'creates invite for new user when inviter is authenticated and authorized to invite' do
      expect {
        post invites_path, params: invite_params.to_json, headers: headers(user)
      }.to change(Invite, :count).by 1
      expect(response).to have_http_status :created
      expect(json[:email]).to eq invite_params[:email]
      expect(json[:invitable_id]).to eq group.id
      expect(json[:sender_id]).to eq user.id
      expect(deliveries.length).to eq 1
      expect(deliveries.first.from).to eq [ENV['MAILER_SENDER']]
      expect(deliveries.first.to).to eq [invite_params[:email]]
      expect(deliveries.first.to_s).to include(
        I18n.t('invitation.invite_mailer.new_user.someone_invited_you',
               sender: user.email, invitable: group.name)
      )
    end

    it 'creates invite for existing user and instantly gives access to existing user' do
      expect(Group.with_member(user2)).not_to include group
      expect {
        post invites_path, params: existing_invite_params.to_json, headers: headers(user)
      }.to change(Invite, :count).by 1
      expect(response).to have_http_status :created
      expect(json[:email]).to eq user2.email
      expect(json[:sender_id]).to eq user.id
      expect(deliveries.length).to eq 1
      expect(deliveries.first.to).to eq [user2.email]
      expect(deliveries.first.to_s).to include(
        I18n.t('invitation.invite_mailer.existing_user.someone_invited_you',
               sender: user.email, invitable: group.name)
      )
      expect(Group.with_member(user2)).to include group
    end

    it 'doesnt create invite for user who already has access to invitable. No email sent' do
      user2.groups << group
      expect(Group.with_member(user2)).to include group
      expect {
        post invites_path, params: existing_invite_params.to_json, headers: headers(user)
      }.not_to change(Invite, :count)
      expect(response).to have_http_status :bad_request
      expect(json[:status]).to eq 'failed'
      expect(json[:errors]).to eq 'User already in group'
      expect(deliveries.length).to eq 0
    end
  end
end
