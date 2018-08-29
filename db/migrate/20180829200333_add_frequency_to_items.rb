class AddFrequencyToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :frequency, :integer, default: 1
  end
end
