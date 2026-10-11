class RegistrationsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_default_cycle

  def new
    redirect_to root_path if current_user
    @user ||= User.new
  end

  def create
    return redirect_to root_path if current_user

    @user = User.new(user_params)
    created = false

    User.transaction do
      if @user.save
        StudyCycle.where(user_id: nil).update_all(user_id: @user.id) if User.count == 1
        reset_session
        session[:user_id] = @user.id
        created = true
      else
        raise ActiveRecord::Rollback
      end
    end

    if created
      redirect_to root_path, notice: "Conta criada. Vamos montar seu ciclo de estudos."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params = params.require(:user).permit(:email, :password, :password_confirmation)
end
