require 'rails_helper'

RSpec.describe 'Items api interactions' do
  before(:each) do
    list
    other_list
  end

  let(:list) { create(:list_with_items) }
  let(:user) { list.user }
  let(:list2) { create(:list, user: user, name: 'user list2') }
  let(:other_list) { create(:list_with_items) }

  let(:new_item) { attributes_for(:full_item).to_json }
  let(:new_invalid_item) { attributes_for(:full_item, :without_name).to_json }
  let(:update_item) { attributes_for(:full_item, name: 'updated').to_json }
  let(:update_item_list) { attributes_for(:item, name: 'in_new_list') }
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

  let(:group_with_users) { create(:group, :with_users, user_traits: [:with_lists]) }
  let(:group_user) { group_with_users.users.first }
  let(:group_user2) { group_with_users.users.last }
  let(:group_list) { group_user2.lists.first }
  let(:group_target_list) { group_with_users.users.second.lists.second }

  context 'Items#index GET' do
    it 'gets all items on list if user is signed in and responds 200 OK' do
      get list_items_path(list.id), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 10
      expect(json[0]).to include(list_id: list.id)
    end

    it 'gets all items from user group member list and responds 200 OK' do
      create_list(:item, 4, list: group_list)
      get list_items_path(group_list.id), headers: headers(group_user)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 4
      expect(json[0]).to include(list_id: group_list.id)
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
  end

  context 'Items#show GET' do
    it 'gets specific item if user is signed in and responds 200 OK' do
      get list_item_path(list.id, first_item), headers: headers(user)
      expect(response).to have_http_status(:ok)
      expect(json[:id]).to eq first_item.id
      expect(json[:list_id]).to eq list.id
    end

    it 'gets specific item from user group member list and responds 200 OK' do
      create_list(:item, 4, list: group_list)
      get list_item_path(group_list.id, group_list.items.first), headers: headers(group_user)
      expect(response).to have_http_status :ok
      expect(json[:id]).to eq group_list.items.first.id
      expect(json[:list_id]).to eq group_list.id
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
        post list_items_path(list.id), params: new_item, headers: headers(user)
      }.to change(Item, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json[:list_id]).to eq list.id
      created_id = json[:id]
      expect(response.headers.to_h).
        to include('Location' => list_item_url(list.id, created_id))
    end

    it 'creates item in user group member list and responds 201 created' do
      expect {
        post list_items_path(group_list.id), params: new_item, headers: headers(group_user)
      }.to change(Item, :count).by 1
      expect(response).to have_http_status :created
      expect(json[:list_id]).to eq group_list.id
      expect(group_list.items.count).to eq 1
      created_id = json[:id]
      expect(response.headers.to_h).
        to include('Location' => list_item_url(group_list.id, created_id))
    end

    it 'does not create item if params are invalid, responds with 400' do
      expect {
        post list_items_path(list.id), params: new_invalid_item, headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:bad_request)
      expect(json[:status]).to eq 'failed'
      expect(json[:errors]).to include "Name can't be blank"
      expect(json).not_to include :id
    end

    it 'responds with unauthorized if user is not signed in' do
      expect {
        post list_items_path(list.id), params: new_item, headers: headers
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:unauthorized)
    end

    it 'broadcasts on list channel after creating an item' do
      expect {
        post list_items_path(list.id), params: new_item, headers: headers(user)
      }.to broadcast_to(list).from_channel(ListChannel).once
    end
  end

  context 'Items#update PUT' do
    it 'updates an item and responds with 200 OK' do
      expect {
        put list_item_path(list.id, second_item), params: update_item, headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:ok)
      expect(second_item.reload.name).to eq 'updated'
      expect(second_item.quantity).to eq 14
      expect(second_item).to have_state(:to_buy)
    end

    it 'updates an item from user group member list and responds with 200 OK' do
      create_list(:item, 4, list: group_list)
      put list_item_path(group_list.id, group_list.items.first),
          params: update_item, headers: headers(group_user)
      expect(response).to have_http_status :ok
      expect(group_list.items.first.reload.name).to eq 'updated'
    end

    it 'does not update list if params are invalid, responds with 400' do
      put list_item_path(list.id, second_item), params: new_invalid_item, headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json[:errors]).to include "Name can't be blank"
      expect(second_item.reload.name).not_to be_nil
    end

    it 'updates item list_id if list belongs to current user and target_list param present. 200 OK' do
      expect {
        put list_item_path(list.id, second_item),
            params: update_item_list.merge(target_list: list2.id).to_json,
            headers: headers(user)
      }.to change { list2.items.count }.by 1
      expect(response).to have_http_status :ok
      expect(second_item.reload.list_id).to eq list2.id
      expect(second_item.name).to eq 'in_new_list'
      expect(list.items).not_to include second_item
    end

    it 'updates item list_id if list belong to user group member, responds 200 OK' do
      create_list(:item, 4, list: group_list)
      moved_item = group_list.items.first
      expect {
        put list_item_path(group_list.id, moved_item),
            params: update_item_list.merge(target_list: group_target_list.id).to_json,
            headers: headers(group_user)
      }.to change { group_target_list.items.count }.by 1
      expect(response).to have_http_status :ok
      expect(moved_item.reload.list_id).to eq group_target_list.id
      expect(moved_item.name).to eq 'in_new_list'
      expect(group_list.items.reload).not_to include moved_item
    end

    it 'does not update item list_id if no target list param is present. 200 OK' do
      expect {
        put list_item_path(list.id, second_item),
            params: update_item_list.to_json,
            headers: headers(user)
      }.not_to change list2.items, :count
      expect(response).to have_http_status :ok
      expect(second_item.reload.list_id).to eq list.id
      expect(second_item.name).to eq 'in_new_list'
      expect(list.items).to include second_item
    end

    it 'doesnt update item list_id if there is already item with same name in target list. 400' do
      list2.items.create(name: second_item.name)
      expect {
        put list_item_path(list.id, second_item),
            params: { target_list: list2.id }.to_json,
            headers: headers(user)
      }.not_to change list2.items, :count
      expect(response).to have_http_status :bad_request
      expect(json[:errors]).to include 'Name has already been taken'
      expect(second_item.reload.list_id).to eq list.id
    end

    it 'does not update item list_id if target list belongs to another user. 401 Unauthorized' do
      expect {
        put list_item_path(list.id, second_item),
            params: update_item_list.merge(target_list: other_list.id).to_json,
            headers: headers(user)
      }.not_to change(other_list.items, :count)
      expect(response).to have_http_status :unauthorized
      expect(json).to include errors: 'unauthorized access'
      expect(second_item.reload.list_id).to eq list.id
      expect(second_item.name).not_to eq 'in_new_list'
      expect(list.items).to include second_item
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
      expect(json[:errors]).to include 'Aasm state invalid state change'
      expect(second_item.reload).to have_state(:to_buy)
      expect(second_item.name).not_to eq 'still_water'
    end

    it 'broadcasts edit on list channel after updating an item but not its list id' do
      expect {
        put list_item_path(list.id, second_item), params: update_item, headers: headers(user)
      }.to broadcast_to(list).from_channel(ListChannel).once
    end

    it 'sends broadcasts to both lists between which item moves after list id update' do
      expect {
        expect {
          put list_item_path(list.id, second_item),
              params: update_item_list.merge(target_list: list2.id).to_json,
              headers: headers(user)
        }.to broadcast_to(list).from_channel(ListChannel).once
      }.to broadcast_to(list2).from_channel(ListChannel).once
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

    it 'mass updates items from user group member list and responds 200 OK' do
      create_list(:item, 4, list: group_list)
      put list_items_path(group_list.id),
          params: { ids: group_list.items.pluck(:id), state: 'missing' }.to_json,
          headers: headers(group_user)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 4
      expect(group_list.items.first.reload.aasm_state).to eq 'missing'
      expect(group_list.items.last.reload.aasm_state).to eq 'missing'
    end

    it 'updates list_id of several items and responds 200 OK' do
      expect {
        put list_items_path(list.id),
            params: { ids: mass_ids, target_list: list2.id }.to_json,
            headers: headers(user)
      }.to change { list2.items.count }.by 3
      expect(response).to have_http_status :ok
      expect(list.items.count).to eq 7
    end

    it 'doesnt update list_id of items if target_list is other users list. 401 Unauthorized' do
      expect {
        put list_items_path(list.id),
            params: { ids: mass_ids, target_list: other_list.id }.to_json,
            headers: headers(user)
      }.not_to change list2.items, :count
      expect(response).to have_http_status :unauthorized
      expect(list.reload.items.count).to eq 10
      expect(json).to include errors: 'unauthorized access'
    end

    it 'doesnt update list_id of items if target_list contains at least one same item. 400' do
      list2.items.create(name: Item.find(mass_ids.first).name)
      expect {
        put list_items_path(list.id),
            params: { ids: mass_ids, target_list: list2.id }.to_json,
            headers: headers(user)
      }.not_to change list2.items, :count
      expect(response).to have_http_status :bad_request
      expect(list.reload.items.count).to eq 10
      expect(json[:errors]).to include 'Name has already been taken'
    end

    it 'does not update any item if all updates have errors and responds 400' do
      list.items.last.update(name: 'occupied')
      put list_items_path(list.id),
          params: { ids: mass_ids, name: 'occupied' }.to_json,
          headers: headers(user)
      expect(response).to have_http_status(:bad_request)
      expect(json[:errors]).to include 'Name has already been taken'
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
      expect(json[:errors]).to include 'Aasm state invalid state change'
      expect(first_item.reload.aasm_state).to eq 'deleted'
      expect(third_item.reload.aasm_state).to eq 'to_buy'
    end

    it 'returns 204 No Content if none of the items exist' do
      put list_items_path(list.id),
          params: { ids: [fake_id, fake_id + 1] }.to_json,
          headers: headers(user)
      expect(response).to have_http_status :no_content
    end

    it 'sends several broadcasts (as many as updated items) during mass update' do
      expect {
        put list_items_path(list.id),
            params: { ids: mass_ids, unit: 'pieces', state: 'bought' }.to_json,
            headers: headers(user)
      }.to broadcast_to(list).from_channel(ListChannel).exactly(3).times
    end

    it 'sends broadcasts to both items between which items move during mass update' do
      expect {
        expect {
          put list_items_path(list.id),
              params: { ids: mass_ids, target_list: list2.id }.to_json,
              headers: headers(user)
        }.to broadcast_to(list).from_channel(ListChannel).exactly(3).times
      }.to broadcast_to(list2).from_channel(ListChannel).exactly(3).times
    end
  end

  context 'Items#destroy DELETE' do
    it 'destroys an item and responds with 200 OK' do
      expect {
        delete list_item_path(list.id, third_item), headers: headers(user)
      }.to change { Item.where(list: list).count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'destroys an item from user group member list and responds 200 OK' do
      create_list(:item, 4, list: group_list)
      expect {
        delete list_item_path(group_list.id, group_list.items.first), headers: headers(group_user)
      }.to change { Item.where(list: group_list).count }.by(-1)
      expect(response).to have_http_status :ok
    end

    it 'returns 204 No Content if item does not exist' do
      expect {
        delete list_item_path(list.id, fake_id), headers: headers(user)
      }.not_to(change(Item, :count))
      expect(response).to have_http_status(:no_content)
    end

    it 'broadcasts on list channel on destroying an item' do
      expect {
        delete list_item_path(list.id, third_item), headers: headers(user)
      }.to broadcast_to(list).from_channel(ListChannel).once
    end
  end
end
