# Shopping list model
class List < ApplicationRecord
  validates :name, presence: true, length: { maximum: 60 }

  belongs_to :user
  has_many :items, dependent: :destroy

  scope :within_groups, ->(user) {
    joins(user: :group_memberships).
      where(group_memberships: { group_id: Group.with_member(user) }).distinct
  }

  def self.user_lists(user)
    if user.groups.present?
      within_groups(user)
    else
      where(user: user)
    end
  end
end
