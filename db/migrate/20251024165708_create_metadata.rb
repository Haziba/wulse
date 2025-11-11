class CreateMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata do |t|
      t.references :document, null: false, foreign_key: true
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :metadata, [:document_id, :key], unique: true
  end
end
