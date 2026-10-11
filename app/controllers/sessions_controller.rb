class SessionsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_default_cycle

  def new
    redirect_to root_path if current_user
  end

  def create
    return redirect_to root_path if current_user

    password = params[:password].to_s
    user = User.find_by(email: params[:email].to_s.strip.downcase)&.authenticate(password) unless password.empty?
    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Bem-vindo de volta."
    else
      flash.now[:alert] = "E-mail ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Você saiu da sua conta."
  end
end
