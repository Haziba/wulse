class RemoveNameFromOer < ActiveRecord::Migration[8.0]
  def change
    remove_column :oers, :name, :string
  end
end
