# == Schema Information
#
# Table name: institutions
#
#  id              :integer          not null, primary key
#  branding_colour :string
#  name            :string
#  storage_total   :integer          default(0)
#  storage_used    :integer          default(0), not null
#  subdomain       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "test_helper"

class InstitutionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
