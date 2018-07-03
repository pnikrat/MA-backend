# User Devise model for authentication and basic user of the application
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  validates :first_name, presence: true

  has_many :lists, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
end
