ActiveAdmin.register Contact do
  menu priority: 3

  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :institution_name
    column :institution_type
    column :contact_name
    column :email
    column :document_volume
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :institution_name
      row :institution_type
      row :contact_name
      row :email
      row :document_volume
      row :requirements
      row :created_at
      row :updated_at
    end
  end

  filter :institution_name
  filter :institution_type
  filter :contact_name
  filter :email
  filter :created_at
end
