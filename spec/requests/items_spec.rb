require 'rails_helper'

RSpec.describe 'Items api interactions' do
  before(:all) do
    @list = FactoryBot.create(:list_with_items)
    @user = @list.user
    @other_list = FactoryBot.create(:list_with_items)
  end

  let(:new_item) {
    FactoryBot.attributes_for(:full_item).to_json
  }
  let(:new_invalid_item) {
    FactoryBot.attributes_for(:full_item, :without_name).to_json
  }
  let(:update_item) {
    FactoryBot.attributes_for(:full_item, name: 'updated').to_json
  }
  let(:buy_item) {
    FactoryBot.attributes_for(:buy).to_json
  }
  let(:buy_item_invalid) {
    FactoryBot.attributes_for(:buy, :with_invalid_event).to_json
  }
  let(:fake_id) { 8888 }
  let(:empty_list) { FactoryBot.create(:list, user: @user) }
  let(:post_list) { FactoryBot.create(:list, user: @user) }
  let(:first_item) { @list.items.first }
  let(:second_item) { @list.items.second }
  let(:third_item) { @list.items.third }
  let(:fourth_item) { @list.items.fourth }
  let(:item_of_other_user) { @other_list.items.first }

  context 'Items#index GET' do
    it 'gets all items on list if user is signed in and responds 200 OK' do
      get list_items_path(@list.id), headers: headers(@user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 10
      expect(json[0]).to include(name: 'still water')
    end

    it 'returns 204 No content if there is no list with given id' do
      get list_items_path(fake_id), headers: headers(@user)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns empty array if list has no items and responds 200 OK' do
      get list_items_path(empty_list.id), headers: headers(@user)
      expect(response).to have_http_status(:ok)
      expect(json.length).to eq 0
    end

    it 'responds with unauthorized if user is not signed in' do
      get list_items_path(@list.id), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Items#show GET' do
    it 'gets specific item if user is signed in and responds 200 OK' do
      get list_item_path(@list.id, first_item), headers: headers(@user)
      expect(response).to have_http_status(:ok)
      expect(json[:id]).to eq first_item.id
      expect(json[:list_id]).to eq @list.id
    end

    it 'doesnt get item in other user list and responds with 204 No Content' do
      get list_item_path(@other_list.id, item_of_other_user.id),
          headers: headers(@user)
      expect(response).to have_http_status(:no_content)
    end

    it 'responds with unauthorized if user is not signed in' do
      get list_item_path(@list.id, first_item), headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Items#create POST' do
    it 'creates an item, returns its id and responds with 201 created' do
      expect {
        post list_items_path(@list.id),
             params: new_item,
             headers: headers(@user)
      }.to change { Item.count }.by(1)
      expect(response).to have_http_status(:created)
      expect(json[:list_id]).to eq @list.id
      created_id = json[:id]
      expect(response.headers.to_h)
        .to include('Location' => list_item_url(@list.id, created_id))
    end

    it 'does not create item if params are invalid, responds with 400' do
      expect {
        post list_items_path(@list.id),
             params: new_invalid_item,
             headers: headers(@user)
      }.not_to(change { Item.count })
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(json).not_to include :id
    end

    it 'responds with unauthorized if user is not signed in' do
      expect {
        post list_items_path(@list.id),
             params: new_item,
             headers: headers
      }.not_to(change { Item.count })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'Items#update PUT' do
    it 'updates an item and responds with 200 OK' do
      expect {
        put list_item_path(@list.id, second_item),
            params: update_item,
            headers: headers(@user)
      }.not_to(change { List.count })
      expect(response).to have_http_status(:ok)
      expect(second_item.reload.name).to eq 'updated'
      expect(second_item.quantity).to eq 14
    end

    it 'does not update list if params are invalid, responds with 400' do
      put list_item_path(@list.id, second_item),
          params: new_invalid_item,
          headers: headers(@user)
      expect(response).to have_http_status(:bad_request)
      expect(json).to include name: ["can't be blank"]
      expect(second_item.reload.name).not_to be_nil
    end
  end

  context 'Items#destroy DELETE' do
    it 'destroys an item and responds with 200 OK' do
      expect {
        delete list_item_path(@list.id, third_item), headers: headers(@user)
      }.to change { Item.where(list: @list).count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 204 No Content if item does not exist' do
      expect {
        delete list_item_path(@list.id, fake_id), headers: headers(@user)
      }.not_to(change { Item.count })
      expect(response).to have_http_status(:no_content)
    end
  end

  context 'Items#toggle PUT' do
    # this route changes the state of item
    it 'changes item into bought from to_buy and responds with 200 OK' do
      expect(fourth_item).to have_state(:to_buy)
      put toggle_list_item_path(@list.id, fourth_item),
          params: buy_item,
          headers: headers(@user)
      expect(response).to have_http_status(:ok)
      expect(fourth_item.reload).to have_state(:bought)
    end

    it 'does not change item state on invalid params, responds 400' do
      expect {
        put toggle_list_item_path(@list.id, fourth_item),
            params: buy_item_invalid,
            headers: headers(@user)
      }.not_to(change { fourth_item.reload.aasm_state })
      expect(response).to have_http_status(:bad_request)
    end
  end
end
