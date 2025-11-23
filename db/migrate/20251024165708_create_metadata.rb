class CreateMetadata < ActiveRecord::Migration[8.0]
  def change
    create_table :metadata, id: :uuid do |t|
      t.references :document, null: false, foreign_key: { on_delete: :cascade }, type: :uuid
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :metadata, [ :document_id, :key ], unique: true
  end
end
