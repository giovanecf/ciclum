class ApplicationController < ActionController::Base
  before_action :purge_expired_guest_users
  before_action :require_login
  before_action :ensure_default_cycle
  helper_method :active_cycle, :current_user

  private

  def require_login
    return if current_user

    redirect_to login_path, alert: "Entre na sua conta para continuar."
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = if session[:user_id].present?
      User.find_by(id: session[:user_id])
    elsif session[:guest_token].present?
      User.find_active_guest(session[:guest_token])
    end
    session.delete(:guest_token) if session[:guest_token].present? && !@current_user
    @current_user
  end

  def purge_expired_guest_users
    Rails.cache.fetch("ciclum/purge_expired_guest_users", expires_in: 1.hour) do
      User.purge_expired_guests!
      true
    end
  end

  def ensure_default_cycle
    cycle = current_user.study_cycles.find_or_create_by!(seed_key: "initial-default") do |item|
      item.name = "Default"
      item.weekly_reference_minutes = 1440
      item.active = current_user.study_cycles.where(active: true).none?
    end
    cycle.activate! if current_user.study_cycles.where(active: true).none?
  end

  def active_cycle = current_user.study_cycles.find_by(active: true) || current_user.study_cycles.find_by!(seed_key: "initial-default")
end
