class PasswordReset < ApplicationRecord
  belongs_to :staff

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :valid_tokens, -> { where("expires_at >= ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def self.find_by_valid_token(token)
    valid_tokens.find_by(token: token)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.expires_at ||= 24.hours.from_now
  end
end
