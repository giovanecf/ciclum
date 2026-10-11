require "test_helper"

class CycleProgressCalculatorTest < ActiveSupport::TestCase
  setup do
    StudySession.delete_all
    CycleSubject.delete_all
    StudyCycle.delete_all
    @cycle = StudyCycle.create!(name: "Default", weekly_reference_minutes: 1440, active: true, seed_key: "initial-default")
    @a = @cycle.cycle_subjects.create!(name: "Português", position: 1, configured_minutes: 60)
    @b = @cycle.cycle_subjects.create!(name: "Constitucional", position: 2, configured_minutes: 60)
  end

  test "first use creates default idempotently and active cycle stays singular" do
    @cycle.update!(weekly_reference_minutes: 1600)
    other = StudyCycle.create!(name: "Outro", weekly_reference_minutes: 800)
    other.activate!
    load Rails.root.join("db/seeds.rb")
    load Rails.root.join("db/seeds.rb")
    assert_equal 1, StudyCycle.where(seed_key: "initial-default").count
    assert_equal 1600, @cycle.reload.weekly_reference_minutes
    assert other.reload.active?
    assert_equal 1, StudyCycle.where(active: true).count
  end

  test "session to current subject reduces remaining and excess becomes future credit" do
    add(@a, 70)
    progress = @cycle.progress
    assert_equal @b, progress.current_subject
    assert_equal 10, progress.credits[@a.id]
  end

  test "name-only subject can be configured later without stalling the rotation" do
    @a.update!(configured_minutes: nil)
    @b.update!(configured_minutes: nil)
    assert_nil @cycle.progress.current_subject
    @a.update!(configured_minutes: 45)
    assert_equal @a, @cycle.progress.current_subject
    assert_equal 45, @cycle.progress.remaining_minutes
  end

  test "a simple session subtracts from the current passage" do
    @a.update!(configured_minutes: 180)
    add(@a, 30)
    assert_equal @a, @cycle.progress.current_subject
    assert_equal 150, @cycle.progress.remaining_minutes
  end

  test "lower and higher current goals recalculate immediately" do
    @a.update!(configured_minutes: 180)
    add(@a, 100)
    @a.update!(configured_minutes: 200)
    assert_equal 100, @cycle.progress.remaining_minutes
    @a.update!(configured_minutes: 60)
    assert_equal @b, @cycle.progress.current_subject
    assert_equal 40, @cycle.progress.credits[@a.id]
  end

  test "credit remains for the next visit and partially covers that passage" do
    @a.update!(configured_minutes: 40)
    @b.update!(configured_minutes: 10)
    add(@a, 60)
    assert_equal @b, @cycle.progress.current_subject
    add(@b, 10)
    progress = @cycle.progress
    assert_equal @a, progress.current_subject
    assert_equal 20, progress.remaining_minutes
  end

  test "other subject credit is consumed when rotation reaches it" do
    add(@b, 180)
    assert_equal @a, @cycle.progress.current_subject
    add(@a, 60)
    progress = @cycle.progress
    assert_equal @a, progress.current_subject
    assert_equal 120, progress.credits[@b.id]
  end

  test "editing retroactive session rebuilds position and credit" do
    first = add(@a, 60)
    second = add(@b, 30)
    assert_equal @b, @cycle.progress.current_subject
    first.update!(minutes: 20)
    progress = @cycle.progress
    assert_equal @a, progress.current_subject
    assert_equal 40, progress.remaining_minutes
    assert_equal 30, progress.credits[@b.id]
    second.destroy!
    assert_equal 0, @cycle.progress.credits[@b.id]
  end

  test "session totals use studied_on and avoid credit duplication" do
    today = Date.current
    add(@a, 30, today)
    add(@b, 90, today - 8)
    assert_equal({today: 30, week: 30, month: 120, total: 120}, @cycle.studied_totals(today))
  end

  test "week totals include Monday and Sunday of the selected week" do
    monday = Date.new(2026, 10, 5)
    add(@a, 25, monday)
    add(@b, 35, monday + 6)
    add(@a, 90, monday - 1)
    assert_equal 60, @cycle.studied_totals(monday + 2)[:week]
  end

  test "recommendations use unnormalized score participation and knowledge factor" do
    @a.update!(questions_count: 30, knowledge_level: 2)
    @b.update!(questions_count: 40, knowledge_level: 3)
    c = @cycle.cycle_subjects.create!(name: "Administrativo", position: 3, questions_count: 30, knowledge_level: 1)
    assert_equal [540, 576, 648], [@cycle.suggested_minutes(@a), @cycle.suggested_minutes(@b), @cycle.suggested_minutes(c)]
  end

  test "changing the current goal immediately creates excess credit" do
    add(@a, 100)
    @a.update!(configured_minutes: 60)
    progress = @cycle.progress
    assert_equal @b, progress.current_subject
    assert_equal 40, progress.credits[@a.id]
  end

  test "changing the weekly reference scales practical goals proportionally" do
    @a.update!(configured_minutes: 720)
    @b.update!(configured_minutes: 864)
    @cycle.update_settings!(weekly_reference_minutes: 1800)
    assert_equal [900, 1080], [@a.reload.configured_minutes, @b.reload.configured_minutes]
  end

  test "knowledge changes suggestions without changing practical goals" do
    @a.update!(questions_count: 30, knowledge_level: 3, configured_minutes: 70)
    @b.update!(questions_count: 70, knowledge_level: 3, configured_minutes: 90)
    before = @cycle.suggested_minutes(@a)
    @a.update!(knowledge_level: 1)
    assert_operator @cycle.suggested_minutes(@a), :>, before
    assert_equal 70, @a.reload.configured_minutes
  end

  test "study totals and credits remain isolated by cycle" do
    add(@a, 30)
    other = StudyCycle.create!(name: "Outro", weekly_reference_minutes: 1440)
    other_subject = other.cycle_subjects.create!(name: "Outra matéria", configured_minutes: 30)
    other.study_sessions.create!(cycle_subject: other_subject, minutes: 20, studied_on: Date.current, sequence: 1)
    assert_equal 30, @cycle.studied_totals[:total]
    assert_equal 20, other.studied_totals[:total]
    other.activate!
    assert_equal other.id, StudyCycle.find_by!(active: true).id
    assert_equal 1, StudyCycle.where(active: true).count
  end

  test "archiving preserves historic study time" do
    add(@a, 20)
    @a.archive!
    assert_equal 20, @cycle.studied_totals[:total]
    assert_equal 1, @a.study_sessions.count
  end

  test "invalid durations, references and cross-cycle subjects are rejected" do
    assert_not StudyCycle.new(name: "Inválido", weekly_reference_minutes: 0).valid?
    assert_not @cycle.study_sessions.new(cycle_subject: @a, minutes: 0, studied_on: Date.current, sequence: 1).valid?
    other = StudyCycle.create!(name: "Outro", weekly_reference_minutes: 10)
    foreign_subject = other.cycle_subjects.create!(name: "Fora")
    assert_not @cycle.study_sessions.new(cycle_subject: foreign_subject, minutes: 10, studied_on: Date.current, sequence: 1).valid?
  end

  test "large credits are consumed by complete rotations without repeated loops" do
    @cycle.cycle_subjects.update_all(configured_minutes: 1)
    add(@a, 1_000_000)
    add(@b, 1_000_000)
    progress = @cycle.progress
    assert_equal @a, progress.current_subject
    assert_equal 1, progress.remaining_minutes
    assert_equal 1_000_000, progress.completed_laps
  end

  private
  def add(subject, minutes, date = Date.current)
    @cycle.study_sessions.create!(cycle_subject: subject, minutes: minutes, studied_on: date, sequence: (@cycle.study_sessions.maximum(:sequence) || 0) + 1)
  end
end
