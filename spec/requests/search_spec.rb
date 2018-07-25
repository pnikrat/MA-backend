require 'rails_helper'

RSpec.describe 'Search api interactions' do
  let(:list_queried) { create(:list_with_items, :query_items) }
  let(:search_result) do
    [list_queried.items.find_by(name: 'apple'), list_queried.items.find_by(name: 'aperol')]
  end
  let(:group_with_users) { create(:group, :with_users, user_traits: [:with_lists]) }
  let(:group_user) { group_with_users.users.last }
  let(:group_list) { group_user.lists.first }

  let(:user) { list_queried.user }
  let(:dupe_item) { create(:item, :deleted, name: 'apple', quantity: 2, list: group_list) }
  let(:non_dupe_item) do
    create(:item, :deleted, name: 'bruchette', price: 2.45, unit: 'piece', list: group_list)
  end

  context 'Items#index GET with query param' do
    it 'gets queried items from list when passed search query and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'coconut' }, headers: headers(user)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 1
      expect(json[0][:id]).to eq list_queried.items.find_by(name: 'coconut').id
      expect(json[0][:list_id]).to eq list_queried.id
    end

    it 'gets multiple queried items from list when passed prefix query and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'ap' }, headers: headers(user)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 2
      expect(json.map { |i| i[:id] }).to eq search_result.map(&:id)
      expect(json.map { |i| i[:list_id] }).to eq search_result.map(&:list_id)
    end

    it 'returns empty array if query does not match any items from list and responds 200 OK' do
      get list_items_path(list_queried.id),
          params: { name: 'unuseful' }, headers: headers(user)
      expect(response).to have_http_status :ok
      expect(json.length).to eq 0
    end

    context 'search other lists' do
      before :each do
        dupe_item
        non_dupe_item
        group_with_users.users << user
      end

      it 'returns results from all lists available to user' do
        get list_items_path(list_queried.id),
            params: { name: 'br' }, headers: headers(user)
        expect(response).to have_http_status :ok
        expect(json.length).to eq 3
        expect(json.pluck(:name)).to match_array %w[bread brocolli bruchette]
      end

      it 'returns results from user other lists' do
        list2 = create(:list, user: user)
        list2.items << create(:item, :deleted, name: 'cobol')
        get list_items_path(list_queried.id),
            params: { name: 'co' }, headers: headers(user)
        expect(response).to have_http_status :ok
        expect(json.length).to eq 2
        expect(json.pluck(:name)).to match_array %w[coconut cobol]
      end
    end
  end
end
