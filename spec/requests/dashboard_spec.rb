require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:institution) { create(:institution, subdomain: 'test', storage_used: 100_000) }
  let(:staff) { create(:staff, institution: institution, password: "password123", status: 'active') }
  let!(:staff2) { create(:staff, institution: institution, status: 'active') }
  let!(:staff3) { create(:staff, institution: institution, status: 'inactive') }

  before do
    host! "#{institution.subdomain}.lvh.me"
    5.times { create(:oer, institution: institution, staff: staff) }
  end

  describe "GET /dashboard" do
    context "when not authenticated" do
      it "redirects to sign in page" do
        get dashboard_path
        expect(response).to redirect_to(new_session_path)
      end

      it "sets an alert flash message" do
        get dashboard_path
        expect(flash[:alert]).to eq("You must be signed in to access this page")
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
        get dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "assigns current stats" do
        get dashboard_path

        expect(assigns(:stats)[:total_documents]).to eq(5)
        expect(assigns(:stats)[:active_staff]).to eq(2)
        expect(assigns(:stats)[:storage_used]).to eq(100_000)
        expect(assigns(:staff_overview).size).to eq(3)
        expect(assigns(:recent_documents).size).to eq(3)
      end

      it "does not include change stats when no historical data exists" do
        get dashboard_path

        expect(assigns(:stats)).not_to have_key(:documents_change)
        expect(assigns(:stats)).not_to have_key(:staff_change)
        expect(assigns(:stats)).not_to have_key(:storage_used_change)
      end

      context "with stats from 1 month ago" do
        let!(:last_month_stat) do
          travel_to 1.month.ago.beginning_of_day do
            create(:institution_stat,
              institution: institution,
              date: Date.current.to_date,
              total_documents: 3,
              active_staff: 1,
              storage_used: 50_000
            )
          end
        end

        it "includes change stats when historical data exists" do
          get dashboard_path

          expect(assigns(:stats)[:documents_change]).to eq(2)  # 5 - 3
          expect(assigns(:stats)[:staff_change]).to eq(1)       # 2 - 1
          expect(assigns(:stats)[:storage_used_change]).to eq(50_000)  # 100_000 - 50_000
        end

        it "handles negative changes" do
          # Update current state to be less than last month
          institution.update!(storage_used: 25_000)

          # Delete 3 OERs
          institution.oers.limit(3).destroy_all

          # Deactivate staff2
          staff2.update!(status: 'inactive')

          get dashboard_path

          expect(assigns(:stats)[:total_documents]).to eq(2)  # 5 - 3 (deleted)
          expect(assigns(:stats)[:documents_change]).to eq(-1)  # 2 - 3
          expect(assigns(:stats)[:active_staff]).to eq(1)  # Only staff, not staff2
          expect(assigns(:stats)[:staff_change]).to eq(0)  # 1 - 1
          expect(assigns(:stats)[:storage_used_change]).to eq(-25_000)  # 25_000 - 50_000
        end
      end

      context "with stats from 2 months ago but not 1 month ago" do
        let!(:two_months_ago_stat) do
          travel_to 2.months.ago.beginning_of_day do
            create(:institution_stat,
              institution: institution,
              date: Date.current.to_date,
              total_documents: 2,
              active_staff: 1,
              storage_used: 30_000
            )
          end
        end

        it "does not include change stats when exactly 1 month ago has no data" do
          get dashboard_path

          expect(assigns(:stats)).not_to have_key(:documents_change)
          expect(assigns(:stats)).not_to have_key(:staff_change)
          expect(assigns(:stats)).not_to have_key(:storage_used_change)
        end
      end

      context "with different institution" do
        let(:other_institution) { create(:institution, subdomain: 'other') }
        let(:other_staff) { create(:staff, institution: other_institution) }

        before do
          # Create OERs for other institution
          3.times { create(:oer, institution: other_institution, staff: other_staff) }
        end

        it "only shows stats for current institution" do
          get dashboard_path

          # Should show 5 OERs from test institution, not 3 from other institution
          expect(assigns(:stats)[:total_documents]).to eq(5)
          expect(assigns(:stats)[:storage_used]).to eq(100_000)
        end
      end
    end
  end
end
