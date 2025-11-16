require "rails_helper"

RSpec.describe PasswordResetMailer, type: :mailer do
  describe "reset_password" do
    let(:institution) { create(:institution) }
    let(:staff) { create(:staff, institution: institution) }
    let(:password_reset) { create(:password_reset, staff: staff) }
    let(:mail) { PasswordResetMailer.reset_password(password_reset) }

    it "renders the headers" do
      expect(mail.subject).to eq("Password Reset Request")
      expect(mail.to).to eq([staff.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi #{staff.name}")
      expect(mail.body.encoded).to match("Reset Password")
      expect(mail.body.encoded).to include(password_reset.token)
    end
  end

end
