institutions = [{
  name: "Wulse Academy",
  subdomain: "wulse-academy",
  logo: File.open(Rails.root.join("db", "seeds", "images", "wulse-academy-logo.png")),
  branding_colour: "#1B2A41",
  storage_total: 1000000000
},{
  name: "University of Wulse",
  subdomain: "uow",
  logo: File.open(Rails.root.join("db", "seeds", "images", "uow-logo.png")),
  branding_colour: "#800020",
  storage_total: 2000000000
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
    (1..30).each do |i|
      document = Document.create(metadata_attributes: [{ key: "title", value: "#{institution.name} Document #{i}" }], staff: staff, institution: institution)
      document.file.attach(File.open(Rails.root.join("db", "seeds", "documents", "Test-Book.epub")))
      GeneratePreviewJob.perform_later(Document.name, document.id, document.file.blob.key)
      puts "Created document: #{document.title}"
    end
  end

  institution
end
