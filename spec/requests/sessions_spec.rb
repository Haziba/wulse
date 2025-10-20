require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:institution) { create(:institution) }
  let(:staff) { create(:staff, institution: institution, password: "password123") }

  before do
    host! "#{institution.subdomain}.lvh.me"
  end

  describe "GET /session/new" do
    it "renders the sign-in page successfully" do
      get new_session_path
      expect(response).to have_http_status(:success)
    end

    it "displays the Welcome Back heading" do
      get new_session_path
      expect(response.body).to include("Welcome Back")
    end

    it "shows the institution subdomain in email placeholder" do
      get new_session_path
      expect(response.body).to include(institution.subdomain)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "creates a session and redirects to root" do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }

        expect(response).to redirect_to(dashboard_path)
        expect(session[:staff_id]).to eq(staff.id)
      end

      it "sets a welcome flash message" do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }

        follow_redirect!
        expect(response.body).to include("Welcome back, #{staff.name}!")
      end
    end

    context "with invalid email" do
      it "returns unprocessable content status" do
        post session_path, params: {
          email: "wrong@email.com",
          password: "password123"
        }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a session" do
        post session_path, params: {
          email: "wrong@email.com",
          password: "password123"
        }

        expect(session[:staff_id]).to be_nil
      end

      it "displays an error message" do
        post session_path, params: {
          email: "wrong@email.com",
          password: "password123"
        }

        expect(response.body).to include("Invalid email or password")
      end

      it "preserves the email in the form after failed attempt" do
        post session_path, params: {
          email: "wrong@email.com",
          password: "password123"
        }

        expect(response.body).to include('value="wrong@email.com"')
      end

      it "responds with turbo stream when Turbo-Frame header is present" do
        post session_path, params: {
          email: "wrong@email.com",
          password: "password123"
        }, headers: { "Turbo-Frame" => "sign_in_form", "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq Mime[:turbo_stream]
        expect(response.body).to include("<turbo-stream action=\"replace\" target=\"sign_in_form\">")
      end
    end

    context "with invalid password" do
      it "returns unprocessable content status" do
        post session_path, params: {
          email: staff.email,
          password: "wrongpassword"
        }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create a session" do
        post session_path, params: {
          email: staff.email,
          password: "wrongpassword"
        }

        expect(session[:staff_id]).to be_nil
      end
    end

    context "with staff from different institution" do
      let(:other_institution) { create(:institution) }
      let(:other_staff) { create(:staff, email: staff.email, institution: other_institution, password: "password123") }

      before { other_staff } # ensure other_staff exists

      it "only authenticates staff from current institution" do
        post session_path, params: {
          email: staff.email,
          password: "password123"
        }

        expect(session[:staff_id]).to eq(staff.id)
        expect(session[:staff_id]).not_to eq(other_staff.id)
      end
    end
  end

  describe "DELETE /session" do
    before do
      post session_path, params: {
        email: staff.email,
        password: "password123"
      }
    end

    it "destroys the session" do
      delete session_path

      expect(session[:staff_id]).to be_nil
    end

    it "redirects to root path" do
      delete session_path

      expect(response).to redirect_to(root_path)
    end

    it "sets a sign out flash message" do
      delete session_path

      follow_redirect!
      expect(response.body).to include("You have been signed out")
    end
  end
end
