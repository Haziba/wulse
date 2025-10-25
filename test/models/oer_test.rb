# == Schema Information
#
# Table name: oers
#
#  id             :integer          not null, primary key
#  document_size  :integer          default(0), not null
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  institution_id :integer          not null
#  staff_id       :integer          not null
#
# Indexes
#
#  index_oers_on_document_size   (document_size)
#  index_oers_on_institution_id  (institution_id)
#  index_oers_on_staff_id        (staff_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#  staff_id        (staff_id => staffs.id)
#
require "test_helper"

class OerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
