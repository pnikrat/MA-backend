# Join model Group <-> User
class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user
end
