class StudySessionsController < ApplicationController
  before_action :set_session, only: [:edit, :update, :destroy]
  def index
    @sessions = active_cycle.study_sessions.includes(:cycle_subject).order(studied_on: :desc, sequence: :desc)
  end
  def new
    @session = active_cycle.study_sessions.new(studied_on: Date.current, cycle_subject_id: active_cycle.progress.current_subject&.id)
  end
  def create
    @session = active_cycle.study_sessions.new(session_params)
    @session.sequence = active_cycle.study_sessions.maximum(:sequence).to_i + 1
    if @session.save
      redirect_to root_path, notice: "Sessão registrada."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    if @session.update(session_params)
      redirect_to study_sessions_path, notice: "Sessão atualizada; rotação e indicadores recalculados."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def destroy
    @session.destroy!
    redirect_to study_sessions_path, notice: "Sessão excluída; rotação e indicadores recalculados."
  end
  private
  def set_session = @session = active_cycle.study_sessions.find(params[:id])
  def session_params = params.require(:study_session).permit(:minutes, :cycle_subject_id, :studied_on)
end
