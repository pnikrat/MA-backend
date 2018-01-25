require 'rails_helper'

RSpec.describe 'User registrations' do
  let(:user) { FactoryBot.attributes_for(:user).to_json }
  let(:user_without_email) do
    FactoryBot.attributes_for(:user, :without_email).to_json
  end
  let(:headers) { { 'Content-Type' => 'application/json' } }

  context 'Registrations#create POST' do
    it 'creates new user and responds with 200 OK' do
      expect { post '/auth', params: user, headers: headers }
        .to change { User.count }.by(1)
      expect(response).to have_http_status(:success)
    end

    it 'does not create new user and responds with fail on missing params' do
      expect { post '/auth', params: user_without_email, headers: headers }
        .not_to(change { User.count })
      expect(response).to have_http_status(422)
    end
  end
end
