class AddAasmStateToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :aasm_state, :string
  end
end
