class StudyCycle < ApplicationRecord
  belongs_to :user
  has_many :cycle_subjects, dependent: :destroy
  has_many :study_sessions, dependent: :destroy
  validates :name, presence: true
  validates :weekly_reference_minutes, numericality: { only_integer: true, greater_than: 0 }

  def activate!
    self.class.transaction do
      user.study_cycles.where(active: true).where.not(id: id).update_all(active: false)
      update!(active: true)
    end
  end

  def update_settings!(attributes)
    success = false
    self.class.transaction do
      previous_reference = weekly_reference_minutes
      if update(attributes)
        if weekly_reference_minutes != previous_reference
          cycle_subjects.where.not(configured_minutes: nil).each do |subject|
            scaled = (subject.configured_minutes * weekly_reference_minutes.to_f / previous_reference).round
            subject.update!(configured_minutes: [scaled, 1].max)
          end
        end
        success = true
      else
        raise ActiveRecord::Rollback
      end
    end
    success
  end

  def progress
    CycleProgressCalculator.new(self).call
  end

  def suggested_minutes(subject)
    StudyTimeRecommender.new(self).suggestion_for(subject)
  end

  def studied_totals(today = Date.current)
    sessions = study_sessions
    week = today.beginning_of_week(:monday)..today.end_of_week(:monday)
    month = today.beginning_of_month..today.end_of_month
    { today: sessions.where(studied_on: today).sum(:minutes), week: sessions.where(studied_on: week).sum(:minutes), month: sessions.where(studied_on: month).sum(:minutes), total: sessions.sum(:minutes) }
  end
end
