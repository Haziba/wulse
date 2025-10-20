class AddLastLoginToStaff < ActiveRecord::Migration[8.0]
  def change
    add_column :staffs, :last_login, :datetime, null: true
  end
end
