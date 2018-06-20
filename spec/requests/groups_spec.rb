require 'rails_helper'

RSpec.describe 'Groups api interactions' do
  let(:user_with_groups) { create(:user, :with_groups) }

  context 'Groups#index GET' do
    it 'gets all user groups if user is signed in and responds 200OK' do
      get groups_path, headers: headers(user_with_groups)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 3
    end
  end
end
