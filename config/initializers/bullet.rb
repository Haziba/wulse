if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true if Rails.env.development?
  Bullet.raise = true if Rails.env.test?

  # Ignore false positives for ActiveStorage internal queries
  Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :record
end
