class MakeStaffPasswordNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :staffs, :password_digest, true
  end
end
