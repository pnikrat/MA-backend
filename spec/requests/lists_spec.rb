require 'rails_helper'

RSpec.describe 'Lists api interactions' do
  before do
    @user = FactoryBot.create(:user_with_lists)
  end

  let(:auth_headers) { @user.create_new_auth_token }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  context 'Lists#index GET' do
    it 'gets all users list if user is signed in and responds 200 OK' do
      get lists_path, headers: headers.merge(auth_headers)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 3
      expect(json[0]).to include(name: 'some list name')
    end

    it 'does not get all users list if user is not signed in' do
      get lists_path, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
