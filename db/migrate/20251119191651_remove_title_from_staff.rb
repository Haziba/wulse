class RemoveTitleFromStaff < ActiveRecord::Migration[8.0]
  def change
    remove_column :staffs, :title, :string
  end
end
