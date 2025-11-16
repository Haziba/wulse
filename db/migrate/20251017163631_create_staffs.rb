class CreateStaffs < ActiveRecord::Migration[8.0]
  def change
    create_table :staffs, id: :uuid do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.references :institution, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
