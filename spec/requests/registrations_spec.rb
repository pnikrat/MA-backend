require 'rails_helper'

RSpec.describe 'User registrations' do
  before(:each) do
    already_existing_user
  end

  let(:already_existing_user) { create(:user) }
  let(:user) { attributes_for(:user) }
  let(:user_without_email) { attributes_for(:user, :without_email).to_json }
  let(:user_without_password_confirmation) do
    attributes_for(:user, :without_password_confirmation).to_json
  end
  let(:user_with_duplicate_email) do
    attributes_for(:user, email: already_existing_user.email).to_json
  end
  let(:group) { create(:group) }
  let(:invite) do
    Invite.create(sender: group.creator, email: user[:email], invitable: group)
  end

  context 'Registrations#create POST' do
    it 'creates new user and responds with 200' do
      expect { post user_registration_path, params: user.to_json, headers: headers }.
        to change(User, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    it 'doesnt create new user with missing params and responds with 422' do
      expect {
        post user_registration_path,
             params: user_without_email, headers: headers
      }.not_to(change(User, :count))
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'doesnt create new user without password confirmation, responds 422' do
      expect {
        post user_registration_path,
             params: user_without_password_confirmation, headers: headers
      }.not_to(change(User, :count))
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'doesnt create new user if email is already in use, responds 422' do
      expect {
        post user_registration_path,
             params: user_with_duplicate_email, headers: headers
      }.not_to(change(User, :count))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json[:errors]).to include email: ['has already been taken']
    end

    it 'creates new user with permissions from invite, responds with 200' do
      expect {
        post user_registration_path,
             params: user.merge(invite_token: invite.token).to_json, headers: headers
      }.to change(User, :count)
      expect(response).to have_http_status(:success)
      expect(group.users).to include User.last
    end
  end
end
