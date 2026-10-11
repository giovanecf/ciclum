class StudySession < ApplicationRecord
  belongs_to :study_cycle
  belongs_to :cycle_subject
  validates :minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :studied_on, presence: true
  validate :subject_belongs_to_cycle_and_is_active

  private

  def subject_belongs_to_cycle_and_is_active
    return unless cycle_subject
    errors.add(:cycle_subject, "não pertence a este ciclo") unless cycle_subject.study_cycle_id == study_cycle_id
    errors.add(:cycle_subject, "está arquivada") if cycle_subject.archived_at? && (new_record? || will_save_change_to_cycle_subject_id?)
  end
end
