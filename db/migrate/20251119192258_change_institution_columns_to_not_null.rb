class ChangeInstitutionColumnsToNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :institutions, :branding_colour, false
    change_column_null :institutions, :name, false
    change_column_null :institutions, :storage_total, false
    change_column_null :institutions, :subdomain, false
  end
end
