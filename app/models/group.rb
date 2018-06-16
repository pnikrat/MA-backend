# Group model representing a collection of users
# who want to share their shopping lists
class Group < ApplicationRecord
  validates :name, presence: true, length: { maximum: 60 }
  validates :name, uniqueness: :creator_id

  has_many :group_memberships, dependent: :destroy
  has_many :users, through: :group_memberships
  belongs_to :creator, class_name: 'User'

  # before_save :assign_creator_to_users, on: :create

  # private

  # def assign_creator_to_users
  #   binding.pry
  #   users << creator unless users.include? creator
  # end
end
