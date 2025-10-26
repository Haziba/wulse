class Dashboard::DocumentsController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in
  before_action :set_document, only: [:edit, :update]

  def index
    documents = Oer.all

    if params[:search].present?
      documents = documents.where("name LIKE ?", "%#{params[:search]}%")
    end

    @pagy, @documents = pagy(documents)
  end

  def new
    @document = Oer.new
  end

  def create
    @document = Oer.new(document_params)
    @document.staff = current_staff

    if @document.save
      @pagy, @documents = pagy(Oer.all)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("document_list", partial: "document_list", locals: { documents: @documents, pagy: @pagy })
        end
        format.html { redirect_to dashboard_documents_path, notice: "Document added successfully!", status: :see_other }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @metadata = ordered_metadata
  end

  def update
    if @document.update(document_params)
      update_preview if new_document_uploaded?
      redirect_to dashboard_documents_path, notice: "Document updated successfully!", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def update_preview
    GeneratePreviewJob.perform_later(@document.class.name, @document.id, @document.document.blob.key)
  end

  def new_document_uploaded?
    @document.document.attached? && params[:oer][:document].present?
  end

  def ordered_metadata
    @ordered_metadata = Oer::REQUIRED_METADATA.map { |key| @document.metadata.find_or_initialize_by(key: key) } + @document.metadata.where.not(key: Oer::REQUIRED_METADATA)
  end

  def set_document
    @document = Oer.includes(:metadata).find(params[:id])
  end

  def document_params
    params.require(:oer).permit(:name, :document, :preview_image, metadata_attributes: [:id, :key, :value, :_destroy])
  end
end
