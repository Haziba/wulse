require 'rails_helper'

RSpec.describe "Dashboard::Profiles", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "password123", name: "John Doe") }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /dashboard/profile/edit" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get edit_dashboard_profile_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }
      end

      it "returns http success" do
        get edit_dashboard_profile_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /dashboard/profile" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        patch dashboard_profile_path, params: { staff: { name: "New Name" } }
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }
      end

      context "updating name only" do
        let(:valid_params) do
          {
            staff: {
              name: "Jane Smith"
            }
          }
        end

        it "updates the staff name" do
          patch dashboard_profile_path, params: valid_params
          expect(staff.reload.name).to eq("Jane Smith")
        end

        it "responds with turbo stream" do
          patch dashboard_profile_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(response.body).to include('turbo-stream action="replace" target="profile_form"')
        end

        it "displays success message" do
          patch dashboard_profile_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include("Profile updated successfully!")
        end

        it "updates the user profile menu" do
          patch dashboard_profile_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.body).to include('turbo-stream action="replace" target="user_profile_menu"')
          expect(response.body).to include("Jane Smith")
        end

        it "does not change the password" do
          old_password_digest = staff.password_digest
          patch dashboard_profile_path, params: valid_params
          expect(staff.reload.password_digest).to eq(old_password_digest)
        end
      end

      context "updating with avatar upload" do
        let(:avatar_file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg'), 'image/jpeg') }

        let(:valid_params) do
          {
            staff: {
              name: "Jane Smith",
              avatar: avatar_file
            }
          }
        end

        it "attaches the avatar" do
          patch dashboard_profile_path, params: valid_params
          expect(staff.reload.avatar).to be_attached
        end

        it "updates the name and avatar" do
          patch dashboard_profile_path, params: valid_params
          staff.reload
          expect(staff.name).to eq("Jane Smith")
          expect(staff.avatar).to be_attached
        end
      end

      context "removing avatar" do
        before do
          staff.avatar.attach(
            io: File.open(Rails.root.join('spec', 'fixtures', 'files', 'avatar.jpg')),
            filename: 'avatar.jpg',
            content_type: 'image/jpeg'
          )
        end

        it "removes the avatar when remove_avatar is set" do
          expect(staff.avatar).to be_attached

          patch dashboard_profile_path, params: {
            staff: { name: staff.name },
            remove_avatar: "1"
          }

          expect(staff.reload.avatar).not_to be_attached
        end

        it "does not remove avatar when remove_avatar is not set" do
          patch dashboard_profile_path, params: {
            staff: { name: "New Name" }
          }

          expect(staff.reload.avatar).to be_attached
        end
      end

      context "changing password" do
        context "with correct current password" do
          let(:password_params) do
            {
              staff: {
                name: staff.name,
                password: "newpassword123",
                password_confirmation: "newpassword123"
              },
              current_password: "password123"
            }
          end

          it "updates the password" do
            patch dashboard_profile_path, params: password_params
            staff.reload
            expect(staff.authenticate("newpassword123")).to be_truthy
          end

          it "cannot authenticate with old password" do
            patch dashboard_profile_path, params: password_params
            staff.reload
            expect(staff.authenticate("password123")).to be_falsey
          end

          it "displays success message" do
            patch dashboard_profile_path, params: password_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response.body).to include("Profile updated successfully!")
          end
        end

        context "with incorrect current password" do
          let(:invalid_password_params) do
            {
              staff: {
                name: staff.name,
                password: "newpassword123",
                password_confirmation: "newpassword123"
              },
              current_password: "wrongpassword"
            }
          end

          it "does not update the password" do
            old_password_digest = staff.password_digest
            patch dashboard_profile_path, params: invalid_password_params
            expect(staff.reload.password_digest).to eq(old_password_digest)
          end

          it "displays error message in turbo stream" do
            patch dashboard_profile_path, params: invalid_password_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response.body).to include('action="prepend" target="toast-container-target"')
          end

          it "responds with turbo stream" do
            patch dashboard_profile_path, params: invalid_password_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

            expect(response.media_type).to eq Mime[:turbo_stream]
            expect(response.body).to include('turbo-stream action="replace" target="profile_form"')
          end

          it "returns unprocessable entity status for html request" do
            patch dashboard_profile_path, params: invalid_password_params
            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        context "with blank password fields" do
          let(:blank_password_params) do
            {
              staff: {
                name: "Updated Name",
                password: "",
                password_confirmation: ""
              }
            }
          end

          it "updates name without changing password" do
            old_password_digest = staff.password_digest
            patch dashboard_profile_path, params: blank_password_params
            staff.reload

            expect(staff.name).to eq("Updated Name")
            expect(staff.password_digest).to eq(old_password_digest)
          end

          it "does not require current password when password is blank" do
            patch dashboard_profile_path, params: blank_password_params
            expect(response).not_to have_http_status(:unprocessable_content)
          end
        end
      end

      context "with validation errors" do
        let(:invalid_params) do
          {
            staff: {
              name: ""
            }
          }
        end

        it "does not update the staff" do
          old_name = staff.name
          patch dashboard_profile_path, params: invalid_params
          expect(staff.reload.name).to eq(old_name)
        end

        it "displays error message in turbo stream" do
          patch dashboard_profile_path, params: invalid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.body).to include('action="prepend" target="toast-container-target"')
        end

        it "responds with turbo stream" do
          patch dashboard_profile_path, params: invalid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.media_type).to eq Mime[:turbo_stream]
          expect(response.body).to include('turbo-stream action="replace" target="profile_form"')
        end
      end

      context "password validation" do
        context "with password too short" do
          let(:short_password_params) do
            {
              staff: {
                name: staff.name,
                password: "short",
                password_confirmation: "short"
              },
              current_password: "password123"
            }
          end

          it "does not update the password" do
            old_password_digest = staff.password_digest
            patch dashboard_profile_path, params: short_password_params
            expect(staff.reload.password_digest).to eq(old_password_digest)
          end

          it "displays validation error in turbo stream" do
            patch dashboard_profile_path, params: short_password_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
            expect(response.body).to include('action="prepend" target="toast-container-target"')
          end
        end

        context "with mismatched password confirmation" do
          let(:mismatched_password_params) do
            {
              staff: {
                name: staff.name,
                password: "newpassword123",
                password_confirmation: "differentpassword"
              },
              current_password: "password123"
            }
          end

          it "does not update the password" do
            old_password_digest = staff.password_digest
            patch dashboard_profile_path, params: mismatched_password_params
            expect(staff.reload.password_digest).to eq(old_password_digest)
          end
        end
      end
    end
  end
end
