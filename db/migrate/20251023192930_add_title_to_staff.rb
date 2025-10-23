class AddTitleToStaff < ActiveRecord::Migration[8.0]
  def change
    add_column :staffs, :title, :string
  end
end
