require 'rails_helper'

RSpec.describe 'User sessions' do
  before(:all) do
    @user = FactoryBot.create(:user)
  end

  let(:user_credentials) do
    { email: @user.email, password: @user.password }.to_json
  end
  let(:fake_user_credentials) do
    { email: @user.email, password: '4321rewq' }.to_json
  end

  context 'Sessions#create POST' do
    it 'user can sign in and response is 200' do
      post user_session_path, params: user_credentials, headers: headers
      expect(response).to have_http_status(:success)
      expect(json[:data]).to include(email: @user.email)
      expect(response.headers).to include 'access-token'
    end

    it 'user cannot sign in with invalid credentials and responds 401' do
      post user_session_path, params: fake_user_credentials, headers: headers
      expect(response).to have_http_status(:unauthorized)
      expect(json[:errors])
        .to include 'Invalid login credentials. Please try again.'
      expect(response.headers).not_to include 'access-token'
    end
  end

  context 'Sessions#destroy DELETE' do
    it 'user can sign out if is signed in and response is 200' do
      delete destroy_user_session_path, headers: headers(@user)
      expect(response).to have_http_status(:success)
    end

    it 'user cannot sign out if not signed in and response is 404' do
      # no access-token in headers
      delete destroy_user_session_path, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
