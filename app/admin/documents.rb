ActiveAdmin.register Document do
  menu priority: 3

  permit_params :staff_id, :institution_id

  filter :staff, as: :select, collection: proc { Staff.all }
  filter :institution, as: :select, collection: proc { Institution.all }
  filter :created_at

  index do
    selectable_column
    id_column
    column :title
    column :author
    column :staff
    column :institution
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :staff
      f.input :institution
    end
    f.actions
  end

  show title: proc { |doc| doc.title } do
    attributes_table title: "Document Details" do
      row :title
      row :author
      row :publishing_date
      row :staff
      row :institution
      row :file do |document|
        if document.file.attached?
          link_to document.file.filename, rails_blob_path(document.file, disposition: "attachment")
        else
          "No file attached"
        end
      end
      row :created_at
    end

    panel "Additional Metadata" do
      additional_metadata = resource.metadata.where.not(key: %w[title author publishing_date])
      if additional_metadata.any?
        table_for additional_metadata do
          column :key
          column :value
        end
      else
        para "No additional metadata"
      end
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
      params.require(:document).permit(:staff_id, :institution_id)
    end
  end
end
