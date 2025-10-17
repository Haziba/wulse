class CreateOers < ActiveRecord::Migration[8.0]
  def change
    create_table :oers do |t|
      t.string :name
      t.references :staff, null: false, foreign_key: true
      t.references :institution, null: false, foreign_key: true

      t.timestamps
    end
  end
end
