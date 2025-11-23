institutions = [ {
  name: "Wulse Academy",
  subdomain: "wulse-academy",
  logo: File.open(Rails.root.join("db", "seeds", "images", "wulse-academy-logo.png")),
  branding_colour: "#1B2A41",
  storage_total: 1000000000
}, {
  name: "University of Wulse",
  subdomain: "uow",
  logo: File.open(Rails.root.join("db", "seeds", "images", "uow-logo.png")),
  branding_colour: "#800020",
  storage_total: 2000000000
} ]

book_titles = [
  "Introduction to Computer Science", "Advanced Mathematics for Engineers", "Modern Physics Principles",
  "Organic Chemistry Fundamentals", "World History: Ancient Civilizations", "Contemporary Literature Analysis",
  "Business Management Essentials", "Financial Accounting Practices", "Marketing Strategy and Planning",
  "Human Anatomy and Physiology", "Environmental Science Today", "Psychology: Mind and Behavior",
  "Political Science Theory", "Sociology in Modern Society", "Philosophy: Ethics and Logic",
  "Data Structures and Algorithms", "Machine Learning Basics", "Web Development Complete Guide",
  "Digital Marketing Handbook", "Project Management Professional", "Economics: Micro and Macro",
  "Statistics for Data Science", "Linear Algebra Applications", "Calculus: Theory and Practice",
  "Biology: Cells to Systems", "Quantum Mechanics Introduction", "Thermodynamics and Energy",
  "Creative Writing Workshop", "Art History: Renaissance to Modern", "Music Theory Fundamentals"
]

document_types = [ "Textbook", "Research Paper", "Manual", "Guide", "Reference Book", "Study Guide" ]
departments = [ "Computer Science", "Mathematics", "Physics", "Chemistry", "History", "Literature",
               "Business", "Finance", "Marketing", "Biology", "Environmental Science", "Psychology",
               "Political Science", "Sociology", "Philosophy", "Engineering", "Economics", "Art", "Music" ]
languages = [ "English", "Spanish", "French", "German", "Mandarin", "Japanese" ]

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
      title = book_titles.sample
      metadata_attributes = [
        { key: "title", value: title },
        { key: "author", value: Faker::Name.name },
        { key: "document_type", value: document_types.sample },
        { key: "department", value: departments.sample },
        { key: "language", value: languages.sample },
        { key: "publishing_date", value: "#{rand(2010..2024)}-#{rand(1..12).to_s.rjust(2, '0')}-#{rand(1..28).to_s.rjust(2, '0')}" }
      ]

      document = Document.create(metadata_attributes: metadata_attributes, staff: staff, institution: institution)
      document.file.attach(File.open(Rails.root.join("db", "seeds", "documents", "Test-Book.epub")))
      GeneratePreviewJob.perform_later(Document.name, document.id, document.file.blob.key)
      puts "Created document: #{document.title}"
    end
  end

  institution
end
