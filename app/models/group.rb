# Group model representing a collection of users
# who want to share their shopping lists
class Group < ApplicationRecord
  validates :name, presence: true, length: { maximum: 60 }
  validates :name, uniqueness: :creator_id

  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  belongs_to :creator, class_name: 'User'

  scope :with_member, ->(user) { joins(:users).where(users: { id: user.id }) }
end
