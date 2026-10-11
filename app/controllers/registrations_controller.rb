class RegistrationsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :ensure_default_cycle

  def new
    redirect_to root_path if current_user && !current_user.guest?
    @user ||= User.new
  end

  def create
    return redirect_to root_path if current_user && !current_user.guest?

    guest = current_user if current_user&.guest?
    @user = User.new(user_params)
    created = false

    User.transaction do
      if @user.save
        if guest
          guest.study_cycles.update_all(user_id: @user.id)
          guest.destroy!
        elsif User.where(guest_token_digest: nil).count == 1
          StudyCycle.where(user_id: nil).update_all(user_id: @user.id)
        end
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

  def user_params = params.require(:user).permit(:full_name, :email, :password, :password_confirmation)
end
