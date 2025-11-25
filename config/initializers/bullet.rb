if defined?(Bullet)
  Bullet.enable = Rails.env.development? || Rails.env.test?
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true if Rails.env.development?
  Bullet.raise = true if Rails.env.test?

  # Ignore false positives for ActiveStorage internal queries
  Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :record
  Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob

  # Document metadata is accessed via methods (title, author, etc) so Bullet can't detect usage
  Bullet.add_safelist type: :unused_eager_loading, class_name: "Document", association: :metadata

  # Document preview_image is conditionally displayed, so not all documents will use it
  Bullet.add_safelist type: :unused_eager_loading, class_name: "Document", association: :preview_image_attachment
end
