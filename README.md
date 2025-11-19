# Wulse – University Document Sharing Platform

Wulse is a Ruby on Rails application for sharing documents within a university or academic institution.

## Table of Contents

1. Requirements
2. Getting Started
3. Database Configuration
4. Active Storage Setup
5. Action Mailer Setup
6. Building Tailwind CSS
7. Running the Application
8. Creating the First Institution and Staff User
9. Production Configuration
10. Contributing
11. License

## Requirements

* Ruby (see `.ruby-version` or `Gemfile`)
* Rails
* Node.js & npm
* PostgreSQL at `localhost:5432`, database `wulse_development`
* Build tools for native gems

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/yourusername/wulse.git
cd wulse
```

### Install Ruby Gems

```bash
bundle install
```

### Install JavaScript Dependencies

```bash
npm install
```

## Database Configuration

Ensure PostgreSQL is running.

```bash
bin/rails db:create
bin/rails db:migrate
```

## Active Storage Setup

```bash
bin/rails db:migrate
```

Configure services in `config/storage.yml`.
Set:

```ruby
config.active_storage.service = :local
```

(or your production service).

## Action Mailer Setup

### Development

```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

Example SMTP:

```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV.fetch("SMTP_ADDRESS", "localhost"),
  port: ENV.fetch("SMTP_PORT", 1025)
}
```

### Production

```ruby
config.action_mailer.default_url_options = { host: "your-production-domain.com", protocol: "https" }
```

Configure SMTP via env vars.

## Building Tailwind CSS

```bash
npm run build
```

## Running the Application

```bash
bin/rails s
```

Visit `http://localhost:3000`.

## Creating the First Institution and Staff User

Open console:

```bash
bin/rails console
```

Create institution:

```ruby
institution = Institution.create!(
  name: "Your University Name",
  branding_colour: "#123456",
  storage_total: 100.gigabytes,
  subdomain: "youruni"
)
```

Create staff:

```ruby
staff = Staff.create!(
  email: "youremail@uni.ac.uk",
  name: "Your Name",
  password: "str0ngP4ss!worD",
  institution: institution
)
```

## Production Configuration

Production uses `DATABASE_URL`.
Example:

```bash
DATABASE_URL=postgres://username:password@host:5432/wulse_production
```

Run before starting:

```bash
RAILS_ENV=production bin/rails db:migrate
npm install
npm run build
RAILS_ENV=production bin/rails assets:precompile
```

## Contributing

1. Fork the repo
2. Create a feature branch
3. Commit and push
4. Open a Pull Request

## License

Licensed under the MIT License. See the `LICENSE` file.
