FactoryBot.define do
  factory :institution do
    name { Faker::University.name }
    subdomain { Faker::Internet.domain_word }
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
