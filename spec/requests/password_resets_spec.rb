require 'rails_helper'

RSpec.describe "PasswordResets", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "oldpassword123") }
  let!(:password_reset) { create(:password_reset, staff: staff) }

  before do
    host! "#{institution.subdomain}.example.com"
  end

  describe "GET /password_resets/:token/edit" do
    context "with valid token" do
      it "renders the password reset form" do
        get edit_password_reset_path(password_reset.token)
        expect(response).to have_http_status(:success)
      end

      it "displays the reset password heading" do
        get edit_password_reset_path(password_reset.token)
        expect(response.body).to include("Reset Password")
      end
    end

    context "with invalid token" do
      it "redirects to sign in page" do
        get edit_password_reset_path("invalid-token")
        expect(response).to have_http_status(:redirect)
      end

      it "sets an error flash message" do
        get edit_password_reset_path("invalid-token")
        expect(flash[:alert]).to eq("Invalid or expired password reset link.")
      end
    end

    context "with expired token" do
      let!(:expired_reset) { create(:password_reset, staff: staff, expires_at: 1.hour.ago) }

      it "redirects to sign in page" do
        get edit_password_reset_path(expired_reset.token)
        expect(response).to have_http_status(:redirect)
      end

      it "sets an expired flash message" do
        get edit_password_reset_path(expired_reset.token)
        expect(flash[:alert]).to eq("Password reset link has expired. Please request a new one.")
      end

      it "deletes the expired token" do
        expect {
          get edit_password_reset_path(expired_reset.token)
        }.to change(PasswordReset, :count).by(-1)
      end
    end
  end

  describe "PATCH /password_resets/:token" do
    context "with valid password" do
      let(:new_password) { "newpassword123" }

      it "updates the staff password" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(staff.reload.authenticate(new_password)).to be_truthy
      end

      it "invalidates the old password" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(staff.reload.authenticate("oldpassword123")).to be_falsey
      end

      it "deletes the password reset token" do
        expect {
          patch password_reset_path(password_reset.token), params: {
            password_reset: {
              password: new_password,
              password_confirmation: new_password
            }
          }
        }.to change(PasswordReset, :count).by(-1)
      end

      it "redirects to sign in page" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(response).to redirect_to(new_session_path)
      end

      it "sets a success flash message" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: new_password,
            password_confirmation: new_password
          }
        }

        expect(flash[:notice]).to eq("Your password has been reset successfully. Please sign in.")
      end
    end

    context "with mismatched passwords" do
      it "does not update the password" do
        old_password_digest = staff.password_digest

        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: "newpassword123",
            password_confirmation: "differentpassword"
          }
        }

        expect(staff.reload.password_digest).to eq(old_password_digest)
      end

      it "renders the edit form again" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: "newpassword123",
            password_confirmation: "differentpassword"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Reset Password")
      end

      it "does not delete the password reset token" do
        expect {
          patch password_reset_path(password_reset.token), params: {
            password_reset: {
              password: "newpassword123",
              password_confirmation: "differentpassword"
            }
          }
        }.not_to change(PasswordReset, :count)
      end
    end

    context "with invalid password (too short)" do
      it "does not update the password" do
        old_password_digest = staff.password_digest

        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: "short",
            password_confirmation: "short"
          }
        }

        expect(staff.reload.password_digest).to eq(old_password_digest)
      end

      it "renders the edit form with error" do
        patch password_reset_path(password_reset.token), params: {
          password_reset: {
            password: "short",
            password_confirmation: "short"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
