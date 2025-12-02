module DemoModeRestricted
  extend ActiveSupport::Concern

  included do
    class_attribute :demo_restricted_actions, default: %i[create update destroy]
    before_action :restrict_demo_mode, if: -> { demo_restricted_actions.include?(action_name.to_sym) }
  end

  private

  def restrict_demo_mode
    return unless Current.institution&.demo?

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: add_toast(alert: "Changes not allowed in Demo mode.")
      end
      format.html do
        redirect_back fallback_location: dashboard_path, alert: "Changes not allowed in Demo mode."
      end
      format.any do
        head :forbidden
      end
    end
  end
end
