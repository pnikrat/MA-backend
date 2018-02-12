require 'rails_helper'

RSpec.describe 'User registrations' do
  before(:all) do
    @user = FactoryBot.create(:user)
  end

  let(:user) { FactoryBot.attributes_for(:user).to_json }
  let(:user_without_email) do
    FactoryBot.attributes_for(:user, :without_email).to_json
  end
  let(:user_without_password_confirmation) do
    FactoryBot.attributes_for(:user, :without_password_confirmation).to_json
  end
  let(:user_with_duplicate_email) do
    FactoryBot.attributes_for(:user, email: @user.email).to_json
  end

  context 'Registrations#create POST' do
    it 'creates new user and responds with 200' do
      expect { post user_registration_path, params: user, headers: headers }
        .to change { User.count }.by(1)
      expect(response).to have_http_status(:success)
    end

    it 'doesnt create new user with missing params and responds with 422' do
      expect {
        post user_registration_path,
             params: user_without_email, headers: headers
      }.not_to(change { User.count })
      expect(response).to have_http_status(422)
    end

    it 'doesnt create new user without password confirmation, responds 422' do
      expect {
        post user_registration_path,
             params: user_without_password_confirmation, headers: headers
      }.not_to(change { User.count })
      expect(response).to have_http_status(422)
    end

    it 'doesnt create new user if email is already in use, responds 422' do
      expect {
        post user_registration_path,
             params: user_with_duplicate_email, headers: headers
      }.not_to(change { User.count })
      expect(response).to have_http_status(422)
      expect(json[:errors]).to include email: ['has already been taken']
    end
  end
end
