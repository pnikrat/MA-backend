# Join model Group <-> User
class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  validates :user_id, uniqueness: { scope: :group_id }
end
