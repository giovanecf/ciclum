class GuestSessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_default_cycle

  def create
    return redirect_to root_path if current_user

    user, token = User.create_guest!
    reset_session
    session[:guest_token] = token
    redirect_to root_path, notice: "Você está usando o Ciclum como visitante. Seus dados expiram após 24 horas sem atividade."
  end
end
