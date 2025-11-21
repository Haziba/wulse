require "rails_helper"

RSpec.describe StaffMailer, type: :mailer do
  describe "welcome_email" do
    let(:institution) { create(:institution) }
    let(:staff) { create(:staff, institution: institution) }
    let(:password_reset) { create(:password_reset, staff: staff) }
    let(:mail) { StaffMailer.welcome_email(staff, password_reset) }

    it "renders the headers" do
      expect(mail.subject).to eq("Welcome to the #{institution.name} Digital Library!")
      expect(mail.to).to eq([staff.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear #{staff.name}")
      expect(mail.body.encoded).to match("Welcome to the #{institution.name} Digital Library")
      expect(mail.body.encoded).to include("Set Your Password")
    end
  end

  describe "deactivation_email" do
    let(:institution) { create(:institution) }
    let(:staff) { create(:staff, institution: institution) }
    let(:mail) { StaffMailer.deactivation_email(staff) }

    it "renders the headers" do
      expect(mail.subject).to eq("Your Account Has Been Deactivated")
      expect(mail.to).to eq([staff.email])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Dear #{staff.name}")
      expect(mail.body.encoded).to include("Your account has been deactivated")
      expect(mail.body.encoded).to include("Please contact your administrator for more information")
    end
  end
end
