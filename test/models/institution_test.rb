# == Schema Information
#
# Table name: institutions
#
#  id              :uuid             not null, primary key
#  branding_colour :string           not null
#  name            :string           not null
#  storage_total   :integer          default(0), not null
#  storage_used    :bigint           default(0), not null
#  subdomain       :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
require "test_helper"

class InstitutionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
