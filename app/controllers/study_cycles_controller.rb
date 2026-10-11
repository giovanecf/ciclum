class StudyCyclesController < ApplicationController
  def index
    @cycles = current_user.study_cycles.order(active: :desc, created_at: :asc)
    @cycle = current_user.study_cycles.new(weekly_reference_minutes: 1440)
  end
  def create
    @cycle = current_user.study_cycles.new(cycle_params)
    if @cycle.save
      @cycle.activate! if params[:study_cycle][:active] == "1"
      redirect_to study_cycles_path, notice: "Ciclo criado."
    else
      @cycles = current_user.study_cycles.order(active: :desc)
      render :index, status: :unprocessable_entity
    end
  end
  def update
    @cycle = current_user.study_cycles.find(params[:id])
    if @cycle.update_settings!(cycle_params)
      @cycle.activate! if params[:study_cycle][:active] == "1"
      redirect_to study_cycles_path, notice: "Ciclo atualizado."
    else
      @cycles = current_user.study_cycles.order(active: :desc)
      render :index, status: :unprocessable_entity
    end
  end
  def activate
    current_user.study_cycles.find(params[:id]).activate!
    redirect_to root_path, notice: "Ciclo ativado."
  end
  def destroy
    cycle = current_user.study_cycles.find(params[:id])
    if cycle.seed_key.present?
      redirect_to study_cycles_path, alert: "O ciclo Default inicial não pode ser excluído."
    else
      cycle.destroy!
      redirect_to study_cycles_path, notice: "Ciclo excluído."
    end
  end
  private
  def cycle_params = params.require(:study_cycle).permit(:name, :weekly_reference_minutes)
end
