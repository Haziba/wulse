ActiveAdmin.register Document do
  permit_params :name, :staff_id, :institution_id

  filter :name
  filter :staff
  filter :institution
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :staff
    column :institution
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :staff
      f.input :institution
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :staff
      row :institution
      row :created_at
    end
  end

  controller do
    def create
      @document = Document.new(document_params)
      @document.save!
      redirect_to admin_document_path(@document)
    end

    private
    def document_params
      params.require(:document).permit(:name, :staff_id, :institution_id)
    end
  end
end
