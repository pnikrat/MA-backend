require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it 'successfully connects when auth params are provided' do
    mock_auth_headers = headers(user)
    token = mock_auth_headers['access-token']
    client = mock_auth_headers['client']
    uid = mock_auth_headers['uid']
    connect "/cable?access-token=#{token}&client=#{client}&uid=#{uid}"
    expect(connection.current_user).to eq user
  end

  it 'rejects connection when no auth headers are provided' do
    expect { connect '/cable' }.to have_rejected_connection
  end
end
