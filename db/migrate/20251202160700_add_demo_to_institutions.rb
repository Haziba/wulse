class AddDemoToInstitutions < ActiveRecord::Migration[8.0]
  def change
    add_column :institutions, :demo, :boolean, default: false, null: false
  end
end
