require 'rails_helper'

RSpec.describe DemoModeRestricted, type: :controller do
  controller(ApplicationController) do
    include DemoModeRestricted

    def create
      render plain: "created"
    end

    def update
      render plain: "updated"
    end

    def destroy
      render plain: "destroyed"
    end

    def index
      render plain: "listed"
    end
  end

  let(:institution) { create(:institution, demo: false) }
  let(:demo_institution) { create(:institution, demo: true) }
  let(:staff) { create(:staff, institution: institution) }
  let(:demo_staff) { create(:staff, institution: demo_institution) }

  before do
    routes.draw do
      resources :anonymous, only: [:index, :create, :update, :destroy]
    end
  end

  describe "default restricted actions" do
    it "restricts create, update, destroy by default" do
      expect(controller.class.demo_restricted_actions).to eq(%i[create update destroy])
    end
  end

  describe "when institution is not in demo mode" do
    before do
      @request.host = "#{institution.subdomain}.lvh.me"
      cookies.signed[:staff_id] = staff.id
    end

    it "allows create action" do
      post :create
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("created")
    end

    it "allows update action" do
      put :update, params: { id: 1 }
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("updated")
    end

    it "allows destroy action" do
      delete :destroy, params: { id: 1 }
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("destroyed")
    end

    it "allows unrestricted actions" do
      get :index
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("listed")
    end
  end

  describe "when institution is in demo mode" do
    before do
      @request.host = "#{demo_institution.subdomain}.lvh.me"
      cookies.signed[:staff_id] = demo_staff.id
    end

    it "blocks create action" do
      post :create
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
    end

    it "blocks update action" do
      put :update, params: { id: 1 }
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
    end

    it "blocks destroy action" do
      delete :destroy, params: { id: 1 }
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
    end

    it "allows unrestricted actions" do
      get :index
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("listed")
    end

    context "with turbo_stream request" do
      it "returns a turbo_stream response" do
        post :create, as: :turbo_stream
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end

    context "with json request" do
      it "returns forbidden status" do
        post :create, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "customizing restricted actions" do
    controller(ApplicationController) do
      include DemoModeRestricted
      self.demo_restricted_actions = %i[create custom_action]

      def create
        render plain: "created"
      end

      def update
        render plain: "updated"
      end

      def custom_action
        render plain: "custom"
      end
    end

    before do
      routes.draw do
        resources :anonymous, only: [:create, :update] do
          member do
            post :custom_action
          end
        end
      end
      @request.host = "#{demo_institution.subdomain}.lvh.me"
      cookies.signed[:staff_id] = demo_staff.id
    end

    it "uses the custom restricted actions" do
      expect(controller.class.demo_restricted_actions).to eq(%i[create custom_action])
    end

    it "blocks custom restricted action" do
      post :custom_action, params: { id: 1 }
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("Changes not allowed in Demo mode.")
    end

    it "allows update when not in restricted list" do
      put :update, params: { id: 1 }
      expect(response).to have_http_status(:success)
      expect(response.body).to eq("updated")
    end
  end
end
