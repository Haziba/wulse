# == Schema Information
#
# Table name: institutions
#
#  id              :uuid             not null, primary key
#  branding_colour :string           not null
#  demo            :boolean          default(FALSE), not null
#  name            :string           not null
#  storage_total   :bigint           default(0), not null
#  storage_used    :bigint           default(0), not null
#  subdomain       :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_institutions_on_subdomain  (subdomain) UNIQUE
#
FactoryBot.define do
  factory :institution do
    name { Faker::University.name }
    sequence(:subdomain) { |n| "#{Faker::Internet.domain_word}#{n}" }
    branding_colour { Faker::Color.hex_color }

    trait :with_logo do
      after(:build) do |institution|
        institution.logo.attach(
          io: File.open(Rails.root.join("db", "seeds", "images", "uow-logo.png")),
          filename: "logo.png",
          content_type: "image/png"
        )
      end
    end
  end
end
