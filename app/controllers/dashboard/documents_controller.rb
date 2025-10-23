class Dashboard::DocumentsController < ApplicationController
  layout "dashboard"
  before_action :require_signed_in

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

  private

  def document_params
    params.require(:oer).permit(:name, :document)
  end
end
