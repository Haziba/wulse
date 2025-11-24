RSpec.configure do |config|
  # Clean up Capybara sessions to prevent file descriptor leaks
  config.after(:each, type: :system) do
    # Reset Capybara session to close file handles
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  # Limit the number of screenshots kept
  Capybara.save_path = Rails.root.join('tmp/capybara')

  # Clean up old screenshots before test run
  config.before(:suite) do
    FileUtils.rm_rf(Dir[Rails.root.join('tmp/capybara/failures_*')])
  end

  # Clean up screenshots after suite to prevent accumulation
  config.after(:suite) do
    # Keep only the most recent 50 failure screenshots
    failures = Dir[Rails.root.join('tmp/capybara/failures_*')].sort_by { |f| File.mtime(f) }
    failures[0...-50].each { |f| FileUtils.rm_f(f) } if failures.size > 50
  end
end
