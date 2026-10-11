class CycleProgressCalculator
  Result = Struct.new(:current_subject, :next_subject, :remaining_minutes, :consumed_minutes, :goal_minutes, :credits, :completed_laps, keyword_init: true)
  def initialize(cycle) = @cycle = cycle

  def call
    subjects = @cycle.cycle_subjects.rotating.to_a
    return Result.new(current_subject: nil, next_subject: nil, remaining_minutes: 0, consumed_minutes: 0, goal_minutes: 0, credits: {}, completed_laps: 0) if subjects.empty?
    credits = Hash.new(0)
    index = 0
    laps = 0
    remaining = subjects[0].configured_minutes
    consume = lambda do
      # Every iteration spends positive credit against a positive goal; this also handles a single-subject cycle.
      while remaining.positive? && credits[subjects[index].id].positive?
        # At the first subject, complete rotations can be consumed in one step.
        if index.zero? && remaining == subjects[0].configured_minutes
          full_rounds = subjects.map { |item| credits[item.id] / item.configured_minutes }.min
          if full_rounds.positive?
            subjects.each { |item| credits[item.id] -= full_rounds * item.configured_minutes }
            laps += full_rounds
            next
          end
        end
        amount = [remaining, credits[subjects[index].id]].min
        remaining -= amount
        credits[subjects[index].id] -= amount
        if remaining.zero?
          old_index = index
          index = (index + 1) % subjects.length
          laps += 1 if old_index == subjects.length - 1
          remaining = subjects[index].configured_minutes
        end
      end
    end
    @cycle.study_sessions.order(:sequence, :id).includes(:cycle_subject).each do |session|
      next unless subjects.any? { |subject| subject.id == session.cycle_subject_id }
      credits[session.cycle_subject_id] += session.minutes
      consume.call
    end
    # At rest, apply any retained credit when the rotation reaches its current subject.
    consume.call
    subject = subjects[index]
    goal = subject.configured_minutes
    Result.new(current_subject: subject, next_subject: effective_next(subjects, index, credits), remaining_minutes: remaining,
      consumed_minutes: goal - remaining, goal_minutes: goal, credits: credits, completed_laps: laps)
  end

  private

  def effective_next(subjects, current_index, credits)
    credits = credits.dup
    candidate_index = (current_index + 1) % subjects.length
    # Skip whole rounds at once, then inspect at most one partial round.
    rounds = subjects.map { |item| credits[item.id] / item.configured_minutes }.min
    subjects.each { |item| credits[item.id] -= rounds * item.configured_minutes } if rounds.positive?
    subjects.length.times do
      candidate = subjects[candidate_index]
      return candidate if credits[candidate.id] < candidate.configured_minutes
      credits[candidate.id] -= candidate.configured_minutes
      candidate_index = (candidate_index + 1) % subjects.length
    end
    subjects[candidate_index]
  end
end
