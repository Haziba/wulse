class CreatePasswordResets < ActiveRecord::Migration[8.0]
  def change
    create_table :password_resets, id: :uuid do |t|
      t.references :staff, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :password_resets, :token, unique: true
  end
end
