class MakeInstitutionSubdomainUnique < ActiveRecord::Migration[8.0]
  def change
    add_index :institutions, :subdomain, unique: true
  end
end
