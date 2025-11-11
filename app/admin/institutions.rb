ActiveAdmin.register Institution do
  permit_params :name, :subdomain, :logo

  filter :name
  filter :subdomain
  filter :created_at

  index do
    selectable_column
    id_column
    column :name
    column :subdomain
    column :created_at
    actions
  end
  
  form do |f|
    f.inputs do
      f.input :name
      f.input :subdomain
      f.input :logo
    end
    f.actions
  end
  
  show do
    attributes_table do
      row :name
      row :subdomain
      row :logo do |institution|
        if institution.logo.attached?
          image_tag url_for(institution.logo), style: "max-width: 50px; max-height: 50px;"
        else
          "No logo uploaded"
        end
      end
      row :created_at
    end
    panel "Staff Members" do
      paginated_collection(institution.staffs.page(params[:page]).per(10), download_links: false) do
        table_for collection do
          column :name
          column :email
          column :created_at
          column "Actions" do |staff|
            link_to "View", admin_staff_path(staff)
          end
        end
      end
    end
    panel "Documents" do
      paginated_collection(institution.documents.page(params[:page]).per(10), download_links: false) do
        table_for collection do
          column :name
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
      @institution = Institution.new(institution_params)
      @institution.save!
      redirect_to admin_institution_path(@institution)
    end

    private
    def institution_params
      params.require(:institution).permit(:name, :subdomain, :logo)
    end
  end
end
