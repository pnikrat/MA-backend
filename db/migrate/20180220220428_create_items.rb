class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.references :list
      t.string :name
      t.integer :quantity
      t.decimal :price, precision: 8, scale: 2
      t.string :unit
      t.timestamps
    end
  end
end
