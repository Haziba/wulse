# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "controllers", to: "controllers/index.js"
pin "controllers/application", to: "controllers/application.js"
pin_all_from "app/assets/builds/controllers", under: "controllers", preload: false

# Pin pdfjs-dist for PDF reader
pin "pdfjs-dist", to: "https://unpkg.com/pdfjs-dist@5.4.296/build/pdf.mjs"

