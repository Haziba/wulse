require 'rails_helper'

RSpec.describe "Admin::Sessions", type: :request do
  let(:admin) { create(:admin, email: 'admin@example.com', password: 'password') }

  describe "GET /admin/login" do
    it "returns http success" do
      get admin_login_path
      expect(response).to have_http_status(:success)
    end

    it "displays the login form" do
      get admin_login_path
      expect(response.body).to include('Wulse Admin')
      expect(response.body).to include('Email')
      expect(response.body).to include('Password')
    end
  end

  describe "POST /admin/login" do
    context "with valid credentials" do
      it "logs in the admin" do
        post admin_login_path, params: { email: admin.email, password: 'password' }
        expect(response).to redirect_to(admin_root_path)
      end

      it "sets the admin session" do
        post admin_login_path, params: { email: admin.email, password: 'password' }
        expect(session[:admin_id]).to eq(admin.id)
      end
    end

    context "with invalid credentials" do
      it "does not log in with wrong password" do
        post admin_login_path, params: { email: admin.email, password: 'wrongpassword' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:admin_id]).to be_nil
      end

      it "does not log in with wrong email" do
        post admin_login_path, params: { email: 'wrong@example.com', password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(session[:admin_id]).to be_nil
      end

      it "displays an error message" do
        post admin_login_path, params: { email: admin.email, password: 'wrongpassword' }
        expect(response.body).to include('Invalid email or password')
      end
    end
  end

  describe "DELETE /admin/logout" do
    before do
      post admin_login_path, params: { email: admin.email, password: 'password' }
    end

    it "logs out the admin" do
      delete admin_logout_path
      expect(response).to redirect_to(admin_login_path)
    end

    it "clears the admin session" do
      delete admin_logout_path
      expect(session[:admin_id]).to be_nil
    end
  end

  describe "ActiveAdmin authentication" do
    before do
      host! "localhost"
    end

    context "when not logged in" do
      it "redirects to login page" do
        get admin_root_path
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context "when logged in" do
      before do
        post admin_login_path, params: { email: admin.email, password: 'password' }
      end

      it "allows access to admin dashboard" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end
  end
end
