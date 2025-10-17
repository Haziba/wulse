class CreateInstitutions < ActiveRecord::Migration[8.0]
  def change
    create_table :institutions do |t|
      t.string :name
      t.string :subdomain

      t.timestamps
    end
  end
end
