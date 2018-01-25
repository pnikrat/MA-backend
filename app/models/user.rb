# User Devise model for authentication and basic user of the application
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  validates :first_name, presence: true
end
