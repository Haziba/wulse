# == Schema Information
#
# Table name: staffs
#
#  id              :integer          not null, primary key
#  email           :string
#  last_login      :datetime
#  name            :string
#  password_digest :string
#  status          :integer          default("active")
#  title           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  institution_id  :integer          not null
#
# Indexes
#
#  index_staffs_on_institution_id  (institution_id)
#
# Foreign Keys
#
#  institution_id  (institution_id => institutions.id)
#
require "test_helper"

class StaffTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
