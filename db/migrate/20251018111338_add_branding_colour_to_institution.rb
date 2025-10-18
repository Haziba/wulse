class AddBrandingColourToInstitution < ActiveRecord::Migration[8.0]
  def change
    add_column :institutions, :branding_colour, :string
  end
end
