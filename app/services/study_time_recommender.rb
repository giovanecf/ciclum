class StudyTimeRecommender
  MULTIPLIERS = { 1 => 1.5, 2 => 1.25, 3 => 1.0, 4 => 0.75, 5 => 0.5 }.freeze
  attr_reader :cycle
  def initialize(cycle) = @cycle = cycle

  def suggestion_for(subject)
    subjects = cycle.cycle_subjects.available
    return nil if subjects.empty? || subjects.any? { |s| s.questions_count.nil? }
    points = subjects.sum { |s| s.questions_count * (s.points_per_question || 1).to_f }
    return nil unless points.positive?
    this_points = subject.questions_count.to_i * (subject.points_per_question || 1).to_f
    (cycle.weekly_reference_minutes * this_points / points * MULTIPLIERS.fetch(subject.knowledge_level)).round
  end
end
