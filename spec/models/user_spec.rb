require 'rails_helper'

RSpec.describe User do
  let(:user) { build(:user) }
  let(:user_without_password) { build(:user, :without_password) }
  let(:user_without_email) { build(:user, :without_email) }
  let(:user_without_first_name) { build(:user, :without_first_name) }

  context 'basic model validations' do
    it 'user with email, password and first_name is valid' do
      expect(user).to be_valid
    end

    it 'user without password is invalid' do
      expect(user_without_password).not_to be_valid
    end

    it 'user without email is invalid' do
      expect(user_without_email).not_to be_valid
    end

    it 'user without first_name is invalid' do
      expect(user_without_first_name).not_to be_valid
    end
  end
end
