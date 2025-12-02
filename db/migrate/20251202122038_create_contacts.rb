class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts, id: :uuid do |t|
      t.string :institution_name
      t.string :institution_type
      t.string :contact_name
      t.string :email
      t.string :document_volume
      t.text :requirements

      t.timestamps
    end
  end
end
