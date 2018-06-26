require 'rails_helper'

RSpec.describe 'Lists api interactions' do
  before(:each) do
    user
    no_list_user
    other_user
  end

  let(:user) { create(:user, :with_lists) }
  let(:no_list_user) { create(:user) }
  let(:other_user) { create(:user, :with_lists) }

  let(:new_list) { attributes_for(:list, :without_user).to_json }
  let(:new_invalid_list) { attributes_for(:list, :without_name).to_json }
  let(:update_list) { attributes_for(:list, :without_user, name: 'updated').to_json }
  let(:first_list) { user.lists.first }
  let(:second_list) { user.lists.second }
  let(:third_list) { user.lists.third }
  let(:first_list_of_other_user) { other_user.lists.first }

  context 'Lists#index GET' do
    it 'gets all users list if user is signed in and responds 200 OK' do
      get lists_path, headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 3
      expect(json[0]).to include(name: 'some list name')
    end

    it 'returns empty array if user has no lists and responds 200 OK' do
      get lists_path, headers: headers(no_list_user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 0
    end

    it 'responds with unauthorized if user is not signed in' do
      get lists_path, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Lists#show GET' do
    it 'gets specific list if user is signed in and responds 200 OK' do
      get list_path(first_list.id), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json[:id]).to eq first_list.id
      expect(json[:user_id]).to eq user.id
    end

    it 'doesnt get list of other user and responds with 204 No Content' do
      get list_path(first_list_of_other_user.id), headers: headers(user)
      expect(response).to have_http_status(:no_content)
    end

    it 'responds with unauthorized if user is not signed in' do
      get list_path(first_list.id), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Lists#create POST' do
    # Dont have to specify user in POST body
    # inferred from current_user
    it 'creates a list, returns its id and responds with 201 Created' do
      expect {
        post lists_path, params: new_list, headers: headers(user)
      }.to change(List, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json[:user_id]).to eq user.id
      created_id = json[:id]
      expect(response.headers.to_h).
        to include('Location' => list_url(created_id))
    end

    it 'does not create list if params are invalid, responds with 400' do
      expect {
        post lists_path, params: new_invalid_list, headers: headers(user)
      }.not_to(change(List, :count))
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(json).not_to include :id
    end

    it 'responds with unauthorized if user is not signed in' do
      expect {
        post lists_path, params: new_list, headers: headers
      }.not_to(change(List, :count))
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Lists#update PUT' do
    it 'updates a list and responds with 200 OK' do
      expect {
        put list_path(second_list.id), params: update_list,
                                       headers: headers(user)
      }.not_to(change(List, :count))
      expect(response).to have_http_status(:ok)
      expect(second_list.reload.name).to eq 'updated'
    end

    it 'does not update list of other user and responds with 204 No Content' do
      put list_path(first_list_of_other_user.id), params: update_list,
                                                  headers: headers(user)
      expect(response).to have_http_status(:no_content)
      expect(first_list_of_other_user.reload.name).not_to eq 'updated'
    end

    it 'does not update list if params are invalid, responds with 400' do
      put list_path(second_list.id), params: new_invalid_list,
                                     headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(second_list.reload.name).not_to be_nil
    end

    it 'responds with unauthorized if user is not signed in' do
      put list_path(second_list.id), params: update_list, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Lists#destroy DELETE' do
    it 'destroys a list and responds with 200 OK' do
      expect {
        delete list_path(third_list.id), headers: headers(user)
      }.to change { List.where(user: user).count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'does not destroy list of other user and responds with 204 No Content' do
      expect {
        delete list_path(first_list_of_other_user.id), headers: headers(user)
      }.not_to(change(List, :count))
      expect(response).to have_http_status(:no_content)
    end

    it 'responds with unauthorized if user is not signed in' do
      expect {
        delete list_path(third_list.id), headers: headers
      }.not_to(change(List, :count))
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
