class ApplicationMailer < ActionMailer::Base
  default from: -> {
    name = Current.try(:institution)&.name || "Wulse"
    "#{name} Digital Library <noreply@wulse.org>"
  }
  layout "mailer"

  def default_url_options
    {
      host: Current.host || ENV.fetch("APP_HOST", "wulse.org"),
      protocol: "https"
    }
  end
end
