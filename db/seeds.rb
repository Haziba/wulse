# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

institutions = [{
  name: "Wulse Academy",
  subdomain: "wulse-academy",
  logo: File.open(Rails.root.join("db", "seeds", "images", "wulse-academy-logo.png"))
},{
  name: "University of Wulse",
  subdomain: "uow",
  logo: File.open(Rails.root.join("db", "seeds", "images", "uow-logo.png"))
}]
  
institutions.each do |institution|
  institution = Institution.create(institution)
  puts "Created institution: #{institution.name}"

  staff = (1..3).map do |i|
    staff = Staff.create(name: "Staff #{i}", email: "staff#{i}@#{institution.subdomain}.com", password: "password", institution: institution)
    puts "Created staff: #{staff.email}"

    staff
  end

  staff.each do |staff|
    (1..3).each do |i|
      oer = Oer.create(name: "#{institution.name} Oer #{i}", staff: staff, institution: institution)
      puts "Created oer: #{oer.name}"
    end
  end

  institution
end