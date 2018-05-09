class AddUniqueItemNameListScopeIndex < ActiveRecord::Migration[5.1]
  def change
    enable_extension :citext unless extensions.include? :citext
    change_column :items, :name, :citext
    add_index :items, %i[name list_id], unique: true
  end
end
