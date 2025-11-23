ActiveAdmin.register Staff do
  permit_params :name, :email, :institution_id, :password, :password_confirmation

  filter :name
  filter :email
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :institution
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :institution
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :email
      row :institution
      row :created_at
    end
    panel "Documents" do
      paginated_collection(staff.documents.page(params[:page]).per(10), download_links: false) do
        table_for collection do
          column :title
          column :created_at
          column "Actions" do |document|
            link_to "View", admin_document_path(document)
          end
        end
      end
    end
  end

  controller do
    def create
      @staff = Staff.new(staff_params)
      @staff.password = SecureRandom.hex(10)
      @staff.save!
      redirect_to admin_staff_path(@staff)
    end

    private
    def staff_params
      params.require(:staff).permit(:name, :email, :institution_id, :password, :password_confirmation)
    end
  end
end
