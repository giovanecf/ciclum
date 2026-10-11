class CycleSubject < ApplicationRecord
  belongs_to :study_cycle
  has_many :study_sessions, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: { scope: :study_cycle_id, conditions: -> { where(archived_at: nil) } }
  validates :knowledge_level, inclusion: { in: 1..5 }
  validates :questions_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :points_per_question, numericality: { greater_than: 0 }, allow_nil: true
  validates :configured_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :available, -> { where(archived_at: nil) }
  scope :rotating, -> { available.where.not(configured_minutes: nil).order(:position, :id) }

  def archive!
    update!(archived_at: Time.current)
  end
end
