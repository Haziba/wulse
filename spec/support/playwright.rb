require 'capybara/playwright'

Capybara.register_driver :playwright do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true
  )
end

Capybara.default_driver = :playwright
Capybara.javascript_driver = :playwright
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :playwright
  end

  config.after(:each, type: :system) do
    begin
      page.execute_script("localStorage.clear(); sessionStorage.clear();")
    rescue StandardError
      # Ignore errors if page is not available
    end
    Capybara.reset_sessions!
  end

  config.before(:suite) do
    if defined?(ActionDispatch::SystemTesting)
      module DisableScreenshots
        def save_image
        end

        def take_failed_screenshot
        end
      end

      ActionDispatch::SystemTesting::TestHelpers::ScreenshotHelper.prepend(DisableScreenshots)
    end
  end
end
