# Preview all emails at http://localhost:3000/rails/mailers/password_reset_mailer
class PasswordResetMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/password_reset_mailer/reset_password
  def reset_password
    PasswordResetMailer.reset_password
  end

end
