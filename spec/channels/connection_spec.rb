require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }

  it 'successfully connects when auth headers are provided' do
    connect '/cable', headers: headers(user)
    expect(connection.current_user).to eq user
  end

  it 'rejects connection when no auth headers are provided' do
    expect { connect '/cable' }.to have_rejected_connection
  end
end
