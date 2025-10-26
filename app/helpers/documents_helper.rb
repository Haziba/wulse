module DocumentsHelper
  def metadata_key_suggestions
    # todo: Check this is scoped to institution
    @metadata_key_suggestions ||= (Oer::SUGGESTED_METADATA + metadata_keys).uniq.sort - Oer::REQUIRED_METADATA
  end

  def metadata_keys
    @metadata_keys ||= Metadata.joins(:oer).where(oer: { institution_id: current_institution.id }).pluck(:key)
  end
end