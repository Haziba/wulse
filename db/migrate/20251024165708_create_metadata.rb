class CreateMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata do |t|
      t.references :oer, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :metadata, [:oer_id, :key], unique: true
  end
end
