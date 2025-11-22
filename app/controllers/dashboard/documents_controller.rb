class Dashboard::DocumentsController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in
  before_action :full_page_if_no_frame, only: [:index]
  before_action :set_document, only: [:show, :edit, :update, :destroy]

  def index
    documents = Document.all
      .order(created_at: :desc)

    if params[:search].present?
      documents = documents.joins(:metadata)
                          .where(metadata: { key: 'title' })
                          .where("metadata.value ILIKE ?", "%#{params[:search]}%")
                          .distinct
    end

    @pagy, @documents = pagy(documents)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("document_list", partial: "document_list", locals: { documents: @documents, pagy: @pagy })
      end
      format.html
    end
  end

  def show
  end

  def new
    @document = Document.new
    @document.metadata.build(key: 'title')
    @document.metadata.build(key: 'author')
    @document.metadata.build(key: 'publishing_date')
  end

  def create
    @document = Document.new(document_params)
    @document.staff = Current.staff

    if @document.save
      update_preview

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            updated_document_list,
            add_toast(notice: "Document added successfully")
          ]
        end
        format.html do
          redirect_to dashboard_documents_path, notice: "Document added successfully!", status: :see_other
        end
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
      @metadata = ordered_metadata
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @document.destroy
    if turbo_frame_request?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            updated_document_list(page: params[:page]),
            add_toast(notice: "Document deleted successfully")
          ]
        end
      end
    else
      return redirect_to dashboard_documents_path, notice: "Document deleted successfully", status: :see_other
    end
  rescue => e
    Rails.logger.error "Error deleting document: #{e.message}"
    respond_to do |format|
      format.turbo_stream { render turbo_stream: add_toast(alert: "Error deleting document") }
      format.html { redirect_to dashboard_documents_path, alert: "Error deleting document", status: :see_other }
    end
  end

  private

  def updated_document_list(page: 1)
    documents = Document.all.order(created_at: :desc)

    if params[:search].present?
      documents = documents.joins(:metadata)
                          .where(metadata: { key: 'title' })
                          .where("metadata.value ILIKE ?", "%#{params[:search]}%")
                          .distinct
    end

    @pagy, @documents = pagy(documents, page: page)
    turbo_stream.update("document_list", partial: "document_list", locals: { documents: @documents, pagy: @pagy })
  end

  def update_preview
    GeneratePreviewJob.perform_later(@document.class.name, @document.id, @document.file.blob.key)
  end

  def new_document_uploaded?
    @document.file.attached? && params[:document][:file].present?
  end

  def ordered_metadata
    @ordered_metadata = Document::REQUIRED_METADATA.map { |key| @document.metadata.find_or_initialize_by(key: key) } + @document.metadata.where.not(key: Document::REQUIRED_METADATA)
  end

  def set_document
    @document = Document.includes(:metadata).find(params[:id])
  rescue
    Rails.logger.error "Document not found: #{params[:id]}"
    redirect_to dashboard_documents_path, alert: "Document not found"
  end

  def document_params
    params.require(:document).permit(:file, :preview_image, metadata_attributes: [:id, :key, :value, :_destroy])
  end
end
