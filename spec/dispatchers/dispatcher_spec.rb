require 'rails_helper'

RSpec.describe Dispatcher, type: :channel do
  let(:mock_data) { { event_type: :test_type, data: { attr1: 'test', attr2: 23 } } }

  it 'sets channel instance variable after initialization' do
    obj = described_class.new(ListChannel)
    assert_equal obj.instance_variable_get(:@channel), ListChannel
  end

  it 'dispatches data in proper format to correct channel via dispatch method' do
    obj = described_class.new(ListChannel)
    target = create(:list)
    expect {
      obj.dispatch(target, mock_data[:event_type], mock_data[:data])
    }.to broadcast_to(target).from_channel(ListChannel).with(
      {
        event_type: 'TEST_TYPE',
        data: mock_data[:data]
      }.to_json
    ).once
  end
end
