class AddStatusToStaff < ActiveRecord::Migration[8.0]
  def change
    add_column :staffs, :status, :integer, default: 0
  end
end
