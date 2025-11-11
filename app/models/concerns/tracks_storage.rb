module TracksStorage
  extend ActiveSupport::Concern

  included do
    after_commit :sync_document_size, on: [:create, :update]
    before_destroy :prepare_storage_cleanup
    after_commit :cleanup_storage, on: :destroy
  end

  def current_document_size
    file.attached? ? file.byte_size : 0
  end

  private

  def sync_document_size
    new_size = current_document_size
    old_size = file_size || 0
    size_delta = new_size - old_size

    if size_delta != 0
      update_column(:file_size, new_size)
      institution.increment!(:storage_used, size_delta)
    end
  end

  def prepare_storage_cleanup
    @size_to_cleanup = file_size || 0
  end

  def cleanup_storage
    institution.decrement!(:storage_used, @size_to_cleanup) if @size_to_cleanup > 0
  end
end
