class CreateGroupMemberships < ActiveRecord::Migration[5.1]
  def change
    create_table :groups do |t|
      t.string :name
      t.belongs_to :creator, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :group_memberships do |t|
      t.belongs_to :group
      t.belongs_to :user
      t.timestamps
    end
  end
end
