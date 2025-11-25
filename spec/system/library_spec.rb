require "rails_helper"

RSpec.describe "Library", type: :system do
  before do
    Capybara.app_host = "http://#{institution.subdomain}.lvh.me"
  end

  after do
    Capybara.app_host = nil
  end

  def hide_sidebar_overlay
    page.execute_script(<<~JS)
      localStorage.removeItem('sidebar_open');
      document.querySelector('[data-sidebar-target="overlay"]')?.classList.add('hidden');
      document.querySelector('[data-sidebar-target="sidebar"]')?.classList.add('-translate-x-full');
      document.querySelector('[data-sidebar-target="sidebar"]')?.classList.remove('translate-x-0');
    JS
  end

  def visit_library_with_clean_storage
    visit library_path
    hide_sidebar_overlay
  end

  let(:institution) { create(:institution, branding_colour: "#1e40af") }
  let(:staff) { create(:staff, institution: institution) }

  let!(:ruby_book) do
    create(:document,
      institution: institution,
      staff: staff,
      title: "Introduction to Ruby Programming",
      author: "Matz Yukihiro"
    )
  end

  describe "searching and reading a book" do
    let!(:js_book) do
      create(:document,
        institution: institution,
        staff: staff,
        title: "JavaScript Fundamentals",
        author: "Brendan Eich"
      )
    end

    it "allows an anonymous user to search for a book and read it" do
      visit_library_with_clean_storage

      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("JavaScript Fundamentals")

      fill_in "q", with: "Ruby"
      find('button[aria-label="Search"]', match: :first).click

      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("Matz Yukihiro")
      expect(page).not_to have_content("JavaScript Fundamentals")

      hide_sidebar_overlay
      find('a[aria-label="Read Introduction to Ruby Programming"]').click

      expect(page).to have_css("#reader-interface")
      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).to have_content("Matz Yukihiro")
      expect(page).to have_content("Table of Contents")
    end
  end

  describe "downloading a book" do
    before do
      ruby_book.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/test_document.pdf")),
        filename: "test_document.pdf",
        content_type: "application/pdf"
      )
    end

    it "allows an anonymous user to download a book" do
      visit library_path

      download_link = find('a[aria-label="Download Introduction to Ruby Programming"]')
      expect(download_link[:href]).to include("test_document.pdf")
      expect(download_link[:href]).to include("disposition=attachment")
    end
  end

  describe "filtering and URL persistence" do
    let!(:article) do
      doc = create(:document, institution: institution, staff: staff, title: "Research Article")
      create(:metadatum, document: doc, key: "document_type", value: "article")
      doc
    end

    let!(:book) do
      doc = create(:document, institution: institution, staff: staff, title: "Programming Book")
      create(:metadatum, document: doc, key: "document_type", value: "book")
      doc
    end

    it "persists search query and filters in the URL" do
      visit_library_with_clean_storage

      expect(page).to have_content("Research Article")
      expect(page).to have_content("Programming Book")
      expect(page).to have_content("Introduction to Ruby Programming")

      fill_in "q", with: "Programming"
      find('button[aria-label="Search"]', match: :first).click

      expect(page).to have_content("Programming Book")
      expect(page).to have_content("Introduction to Ruby Programming")
      expect(page).not_to have_content("Research Article")
      expect(current_url).to include("q=Programming")

      find('input[name="document_type[]"][value="book"]').uncheck

      expect(page).not_to have_content("Programming Book")
      expect(current_url).to include("f=")

      filtered_url = current_url
      visit filtered_url

      expect(find_field("q").value).to eq("Programming")
      expect(find('input[name="document_type[]"][value="book"]')).not_to be_checked
      expect(find('input[name="document_type[]"][value="article"]')).to be_checked
      expect(page).not_to have_content("Programming Book")
    end
  end

  describe "PDF reader" do
    let!(:pdf_book) do
      doc = create(:document,
        institution: institution,
        staff: staff,
        title: "Test PDF Book",
        author: "PDF Author"
      )
      doc.file.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/large.pdf")),
        filename: "large.pdf",
        content_type: "application/pdf"
      )
      doc
    end

    before do
      visit_library_with_clean_storage
      find('a[aria-label="Read Test PDF Book"]').click
      expect(page).to have_css('[data-controller="pdf-reader"]')
      expect(page).not_to have_content("Error loading PDF", wait: 10)
      expect(page).to have_content("1 / 1", wait: 10)
    end

    it "loads the PDF and displays navigation controls" do
      expect(page).to have_css("#reader-interface")
      expect(page).to have_content("Table of Contents")
      expect(page).to have_content("Page 1 of 1")
      expect(page).to have_button("Start")
      expect(page).to have_button("End")
      expect(page).to have_button("Go")
    end
  end

  describe "filter list controls" do
    let!(:cs_book) do
      doc = create(:document, institution: institution, staff: staff, title: "CS Book")
      create(:metadatum, document: doc, key: "department", value: "computer science")
      create(:metadatum, document: doc, key: "language", value: "english")
      doc
    end

    let!(:econ_article) do
      doc = create(:document, institution: institution, staff: staff, title: "Economics Article")
      create(:metadatum, document: doc, key: "department", value: "economics")
      create(:metadatum, document: doc, key: "language", value: "spanish")
      doc
    end

    let!(:history_paper) do
      doc = create(:document, institution: institution, staff: staff, title: "History Paper")
      create(:metadatum, document: doc, key: "department", value: "history")
      create(:metadatum, document: doc, key: "language", value: "french")
      doc
    end

    describe "'all' button" do
      it "checks all checkboxes in the category" do
        visit library_path

        find('input[name="department[]"][value="computer science"]').uncheck
        expect(page).to have_selector('input[name="department[]"][value="computer science"]:not(:checked):not(:disabled)')
        sleep 0.1

        find('input[name="department[]"][value="economics"]').uncheck
        expect(page).to have_selector('input[name="department[]"][value="economics"]:not(:checked):not(:disabled)')
        expect(page).not_to have_content("CS Book")
        expect(page).not_to have_content("Economics Article")
        sleep 0.1

        within "#filter-category-department" do
          find('button[data-action="click->filter-list#selectAll"]').click
        end

        expect(page).to have_content("CS Book")
        expect(page).to have_content("Economics Article")
        expect(page).to have_content("History Paper")

        expect(find('input[name="department[]"][value="computer science"]')).to be_checked
        expect(find('input[name="department[]"][value="economics"]')).to be_checked
        expect(find('input[name="department[]"][value="history"]')).to be_checked
      end

      it "updates the URL with compressed filter parameter" do
        visit library_path

        find('input[name="department[]"][value="computer science"]').uncheck
        expect(page).to have_selector('input[name="department[]"][value="computer science"]:not(:checked):not(:disabled)')
        sleep 0.1

        within "#filter-category-department" do
          expect(page).to have_selector('button[data-action="click->filter-list#selectAll"]')
          find('button[data-action="click->filter-list#selectAll"]').click
        end

        expect(page).to have_selector('input[name="department[]"][value="computer science"]:checked:not(:disabled)')
        expect(current_url).not_to include("department[]=")
        expect(current_url).not_to include("f=")
      end
    end

    describe "'only' button" do
      it "unchecks all other checkboxes in the category" do
        visit library_path

        expect(page).to have_content("CS Book")
        expect(page).to have_content("Economics Article")
        expect(page).to have_content("History Paper")

        within find('label', text: /Economics/) do
          find('button', text: 'only').click
        end

        expect(page).not_to have_content("CS Book")
        expect(page).to have_content("Economics Article")
        expect(page).not_to have_content("History Paper")

        expect(find('input[name="department[]"][value="computer science"]')).not_to be_checked
        expect(find('input[name="department[]"][value="economics"]')).to be_checked
        expect(find('input[name="department[]"][value="history"]')).not_to be_checked
      end

      it "updates the URL with compressed filter parameter" do
        visit library_path

        within find('label', text: /Economics/) do
          find('button', text: 'only').click
        end

        expect(page).to have_content("Economics Article")
        expect(page).not_to have_content("CS Book")
        expect(current_url).to include("f=")
      end

      it "filters results to only the selected option" do
        visit library_path

        within find('label', text: /Computer Science/) do
          find('button', text: 'only').click
        end

        expect(page).to have_content("CS Book")
        expect(page).not_to have_content("Economics Article")
        expect(page).not_to have_content("History Paper")
        expect(page).not_to have_content("Introduction to Ruby Programming")
      end

      it "works across different filter categories independently" do
        visit library_path

        within "#filter-category-department" do
          within find('label', text: /Economics/) do
            find('button', text: 'only').click
          end
        end

        expect(page).to have_content("Economics Article")
        expect(page).not_to have_content("CS Book")

        within "#filter-category-language" do
          within find('label', text: /Spanish/) do
            find('button', text: 'only').click
          end
        end

        expect(page).to have_content("Economics Article")
        expect(page).not_to have_content("CS Book")
        expect(page).not_to have_content("History Paper")
      end
    end
  end

  describe "EPUB reader" do
    let!(:epub_book) do
      doc = create(:document,
        institution: institution,
        staff: staff,
        title: "Test EPUB Book",
        author: "Test Author"
      )
      doc.file.attach(
        io: File.open(Rails.root.join("db/seeds/documents/Test-Book.epub")),
        filename: "Test-Book.epub",
        content_type: "application/epub+zip"
      )
      doc
    end

    before do
      visit_library_with_clean_storage
      find('a[aria-label="Read Test EPUB Book"]').click
      expect(page).to have_css('[data-controller="epub-reader"]')
      expect(page).to have_content("Location 0/", wait: 10)
    end

    it "loads the EPUB and displays navigation controls" do
      expect(page).to have_css("#reader-interface")
      expect(page).to have_content("Table of Contents")
      expect(page).to have_button("Start")
      expect(page).to have_button("End")
      expect(page).to have_button("Go")
    end

    it "navigates with Previous and Next buttons" do
      expect(page).to have_content("Location 0/")

      next_btn = find('[data-epub-reader-target="nextButton"]')
      page.execute_script("arguments[0].click()", next_btn)
      expect(page).to have_content("Location 1/", wait: 5)

      prev_btn = find('[data-epub-reader-target="prevButton"]')
      page.execute_script("arguments[0].click()", prev_btn)
      expect(page).to have_content("Location 0/", wait: 5)
    end

    it "navigates with Start and End buttons" do
      click_button "End"
      expect(page).not_to have_content("Location 0/", wait: 5)

      click_button "Start"
      expect(page).to have_content("Location 0/", wait: 5)
    end

    it "navigates with Go to Page" do
      fill_in type: "number", with: "5"
      click_button "Go"
      expect(page).to have_content("Location 5/", wait: 5)
    end

    it "displays chapter links in the sidebar" do
      toggle_btn = find('#reader-toolbar button[data-action*="toggleSidebar"]')
      page.execute_script("arguments[0].click()", toggle_btn)
      expect(page).to have_css('[data-epub-reader-target="outlineContainer"]', wait: 5)
      expect(page).to have_css('[data-epub-reader-target="outlineContainer"] .cursor-pointer')
    end
  end
end
