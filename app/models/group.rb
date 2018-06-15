# Group model representing a collection of users
# who want to share their shopping lists
class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  belongs_to :creator, class_name: 'User'
end
