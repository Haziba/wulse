class CreateStaffs < ActiveRecord::Migration[8.0]
  def change
    create_table :staffs do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.references :institution, null: false, foreign_key: true

      t.timestamps
    end
  end
end
