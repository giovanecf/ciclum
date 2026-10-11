class CycleSubjectsController < ApplicationController
  before_action :set_subject, only: [:edit, :update, :archive, :move_up, :move_down, :apply_suggestion]
  def index
    @subjects = active_cycle.cycle_subjects.order(:archived_at, :position, :id)
    @subject = active_cycle.cycle_subjects.new(knowledge_level: 3, position: (@subjects.maximum(:position) || 0) + 1)
  end
  def create
    @subject = active_cycle.cycle_subjects.new(subject_params)
    @subject.position = active_cycle.cycle_subjects.maximum(:position).to_i + 1
    if @subject.save
      redirect_to cycle_subjects_path, notice: "Disciplina adicionada."
    else
      @subjects = active_cycle.cycle_subjects.order(:archived_at, :position)
      render :index, status: :unprocessable_entity
    end
  end
  def edit; end
  def update
    if @subject.update(subject_params)
      redirect_to cycle_subjects_path, notice: "Disciplina atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  def archive
    if @subject.archived_at?
      @subject.update!(archived_at: nil)
    else
      @subject.archive!
    end
    redirect_to cycle_subjects_path, notice: "Disciplina atualizada na rotação."
  end
  def move_up = move(-1)
  def move_down = move(1)
  def apply_suggestion
    suggestion = active_cycle.suggested_minutes(@subject)
    if suggestion
      @subject.update!(configured_minutes: [suggestion, 1].max)
      redirect_to cycle_subjects_path, notice: "Sugestão aplicada como meta prática."
    else
      redirect_to cycle_subjects_path, alert: "Sugestão indisponível: informe os dados da prova."
    end
  end
  def destroy
    subject = active_cycle.cycle_subjects.find(params[:id])
    subject.archive!
    redirect_to cycle_subjects_path, notice: "Disciplina arquivada; o histórico foi preservado."
  end
  private
  def set_subject = @subject = active_cycle.cycle_subjects.find(params[:id])
  def subject_params = params.require(:cycle_subject).permit(:name, :questions_count, :points_per_question, :knowledge_level, :configured_minutes)
  def move(delta)
    subjects = active_cycle.cycle_subjects.available.order(:position, :id).to_a
    from = subjects.index(@subject)
    target = from + delta
    if target.between?(0, subjects.length - 1)
      other = subjects[target]
      CycleSubject.transaction do
        @subject.update!(position: -1)
        other.update!(position: from + 1)
        @subject.update!(position: target + 1)
      end
    end
    redirect_to cycle_subjects_path
  end
end
