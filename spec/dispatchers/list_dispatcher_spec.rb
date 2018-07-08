require 'rails_helper'

RSpec.describe ListDispatcher do
  let(:list) { create(:list) }
  let(:mock_data) { { event_type: :test_type, data: { attr1: 'test', attr2: 23 } } }
  let(:obj) { described_class.new(list) }

  it 'sets target instance variable and inits dispatcher object after initialization' do
    assert_equal obj.instance_variable_get(:@target), list
    assert_equal obj.instance_variable_get(:@service).class, Dispatcher
  end

  it 'passes data to dispatcher after invoking ws_event method' do
    dispatcher = obj.instance_variable_get(:@service)
    expect(dispatcher).to receive(:dispatch).with(list, mock_data[:event_type], mock_data[:data])
    obj.ws_event(mock_data[:event_type], mock_data[:data])
  end
end
