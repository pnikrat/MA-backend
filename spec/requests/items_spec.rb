require 'rails_helper'

RSpec.describe 'Items api interactions' do
  before(:each) do
    list
    other_list
  end

  let(:list) { create(:list_with_items) }
  let(:user) { list.user }
  let(:other_list) { create(:list_with_items) }
  let(:list_queried) { create(:list_with_items, :query_items) }
  let(:search_result) do
    [list_queried.items.find_by(name: 'apple'), list_queried.items.find_by(name: 'aperol')]
  end

  let(:new_item) { attributes_for(:full_item).to_json }
  let(:new_invalid_item) { attributes_for(:full_item, :without_name).to_json }
  let(:update_item) { attributes_for(:full_item, name: 'updated').to_json }
  let(:buy_item) { attributes_for(:state_change, desired_state: 'bought').to_json }
  let(:undo_item) { attributes_for(:state_change, desired_state: 'to_buy').to_json }
  let(:not_in_shop_item) do
    attributes_for(:state_change, :with_other_changes, desired_state: 'missing').to_json
  end
  let(:buy_item_invalid) { attributes_for(:state_change, :with_invalid_event).to_json }
  let(:mass_ids) { list.items.first(3).pluck(:id) }
  let(:fake_id) { 8888 }
  let(:empty_list) { create(:list, user: user) }
  let(:post_list) { create(:list, user: user) }
  let(:first_item) { list.items.first }
  let(:second_item) { list.items.second }
  let(:third_item) { list.items.third }
  let(:item_of_other_user) { other_list.items.first }

  context 'Items#index GET' do
    it 'gets all items on list if user is signed in and responds 200 OK' do
      get list_items_path(list.id), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 10
      expect(json[0]).to include(list_id: list.id)
    end

    it 'returns 204 No content if there is no list with given id' do
      get list_items_path(fake_id), headers: headers(user)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns empty array if list has no items and responds 200 OK' do
      get list_items_path(empty_list.id), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 0
    end

    it 'responds with unauthorized if user is not signed in' do
      get list_items_path(list.id), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'gets queried items from list when passed search query and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'coconut' }, headers: headers(list_queried.user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 1
      expect(json[0][:id]).to eq list_queried.items.find_by(name: 'coconut').id
      expect(json[0][:list_id]).to eq list_queried.id
    end

    it 'gets multiple queried items from list when passed prefix query and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'ap' }, headers: headers(list_queried.user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 2
      expect(json.map { |i| i[:id] }).to eq search_result.map(&:id)
      expect(json.map { |i| i[:list_id] }).to eq search_result.map(&:list_id)
    end

    it 'returns empty array if query does not match any items from list and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'unuseful' }, headers: headers(list_queried.user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 0
    end
  end

  context 'Items#show GET' do
    it 'gets specific item if user is signed in and responds 200 OK' do
      get list_item_path(list.id, first_item), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json[:id]).to eq first_item.id
      expect(json[:list_id]).to eq list.id
    end

    it 'doesnt get item in other user list and responds with 204 No Content' do
      get list_item_path(other_list.id, item_of_other_user.id),
          headers: headers(user)
      expect(response).to have_http_status(:no_content)
    end

    it 'responds with unauthorized if user is not signed in' do
      get list_item_path(list.id, first_item), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Items#create POST' do
    it 'creates an item, returns its id and responds with 201 created' do
      expect {
        post list_items_path(list.id),
             params: new_item,
             headers: headers(user)
      }.to change(Item, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json[:list_id]).to eq list.id
      created_id = json[:id]
      expect(response.headers.to_h).
        to include('Location' => list_item_url(list.id, created_id))
    end

    it 'does not create item if params are invalid, responds with 400' do
      expect {
        post list_items_path(list.id),
             params: new_invalid_item,
             headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(json).not_to include :id
    end

    it 'responds with unauthorized if user is not signed in' do
      expect {
        post list_items_path(list.id),
             params: new_item,
             headers: headers
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Items#update PUT' do
    it 'updates an item and responds with 200 OK' do
      expect {
        put list_item_path(list.id, second_item),
            params: update_item,
            headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:ok)
      expect(second_item.reload.name).to eq 'updated'
      expect(second_item.quantity).to eq 14
      expect(second_item).to have_state(:to_buy)
    end

    it 'does not update list if params are invalid, responds with 400' do
      put list_item_path(list.id, second_item),
          params: new_invalid_item,
          headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(second_item.reload.name).not_to be_nil
    end

    it 'updates a state of an item alone and responds with 200 OK' do
      expect(second_item).to have_state(:to_buy)
      put list_item_path(list.id, second_item), params: buy_item, headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(second_item.reload).to have_state(:bought)
      put list_item_path(list.id, second_item), params: undo_item, headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(second_item.reload).to have_state(:to_buy)
    end

    it 'updates a state of an item along with other attributes and responds with 200 OK' do
      put list_item_path(list.id, second_item),
          params: not_in_shop_item,
          headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(second_item.reload.unit).to eq 'pieces'
      expect(second_item.quantity).to eq 10
      expect(second_item).to have_state(:missing)
    end

    it 'does not update list if desired state is invalid, responds with 400' do
      put list_item_path(list.id, second_item),
          params: buy_item_invalid,
          headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json).to include aasm_state: ['invalid state change']
      expect(second_item.reload).to have_state(:to_buy)
      expect(second_item.name).not_to eq 'still_water'
    end
  end

  context 'Items#mass_action PUT' do
    it 'updates several items and responds 200 OK' do
      expect {
        put list_items_path(list.id),
            params: { ids: mass_ids, unit: 'pieces', state: 'bought' }.to_json,
            headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 3
      expect(first_item.reload.aasm_state).to eq 'bought'
      expect(third_item.reload.aasm_state).to eq 'bought'
    end

    it 'does not update any item if all updates have errors and responds 400' do
      list.items.last.update(name: 'occupied')
      put list_items_path(list.id),
          params: { ids: mass_ids, name: 'occupied' }.to_json,
          headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json.first.last).to include name: ['has already been taken']
      expect(first_item.reload.name).not_to eq 'occupied'
      expect(third_item.reload.name).not_to eq 'occupied'
    end

    it 'does not update any item if one of them has errors and responds 400' do
      first_item.update(aasm_state: 'deleted')
      expect(first_item.reload.aasm_state).to eq 'deleted'
      put list_items_path(list.id),
          params: { ids: mass_ids, state: 'bought' }.to_json,
          headers: headers(user)
      expect(response).to have_http_status :bad_request
      expect(json.first.last).to include aasm_state: ['invalid state change']
      expect(first_item.reload.aasm_state).to eq 'deleted'
      expect(third_item.reload.aasm_state).to eq 'to_buy'
    end

    it 'returns 204 No Content if none of the items exist' do
      put list_items_path(list.id),
          params: { ids: [fake_id, fake_id + 1] }.to_json,
          headers: headers(user)
      expect(response).to have_http_status :no_content
    end
  end

  context 'Items#destroy DELETE' do
    it 'destroys an item and responds with 200 OK' do
      expect {
        delete list_item_path(list.id, third_item), headers: headers(user)
      }.to change { Item.where(list: list).count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 204 No Content if item does not exist' do
      expect {
        delete list_item_path(list.id, fake_id), headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:no_content)
    end
  end
end
