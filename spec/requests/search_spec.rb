require 'rails_helper'

RSpec.describe 'Search api interactions' do
  let(:list_queried) { create(:list_with_items, :query_items) }
  let(:search_result) do
    [list_queried.items.find_by(name: 'apple'), list_queried.items.find_by(name: 'aperol')]
  end

  context 'Items#index GET with query param' do
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
end
