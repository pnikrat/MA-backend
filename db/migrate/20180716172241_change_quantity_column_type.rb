class ChangeQuantityColumnType < ActiveRecord::Migration[5.1]
  def change
    change_column :items, :quantity, :decimal, precision: 8, scale: 2
  end
end
