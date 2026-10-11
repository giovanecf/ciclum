require "test_helper"

class ApplicationFlowTest < ActionDispatch::IntegrationTest
  setup do
    StudySession.delete_all
    CycleSubject.delete_all
    StudyCycle.delete_all
  end

  test "first visit lands on the empty default dashboard and core screens render" do
    get root_path
    assert_response :success
    assert_select "h2", "Vamos montar seu ciclo"
    assert_equal 4, css_select(".stat-time strong").count { |node| node.text == "0 min" }
    assert_equal "Default", StudyCycle.find_by!(seed_key: "initial-default").name
    get cycle_subjects_path
    assert_response :success
    assert_select "input[name='cycle_subject[name]']"
  end

  test "add a subject, record a session and edit the session" do
    get root_path
    post cycle_subjects_path, params: {cycle_subject: {name: "Português", configured_minutes: 60, knowledge_level: 3}}
    assert_response :redirect
    subject = CycleSubject.find_by!(name: "Português")
    post study_sessions_path, params: {study_session: {minutes: 25, cycle_subject_id: subject.id, studied_on: Date.current}}
    assert_response :redirect
    session = StudySession.find_by!(cycle_subject: subject)
    assert_equal 25, session.minutes
    patch study_session_path(session), params: {study_session: {minutes: 30, cycle_subject_id: subject.id, studied_on: Date.current - 2}}
    assert_response :redirect
    session.reload
    assert_equal 30, session.minutes
    assert_equal Date.current - 2, session.studied_on
    get root_path
    assert_response :success
    assert_includes response.body, "30 min"
  end

  test "reference changes scale goals while applying suggestions stays explicit" do
    get root_path
    post cycle_subjects_path, params: {cycle_subject: {name: "Português", questions_count: 30, knowledge_level: 2, configured_minutes: 720}}
    post cycle_subjects_path, params: {cycle_subject: {name: "Constitucional", questions_count: 40, knowledge_level: 3, configured_minutes: 864}}
    a = CycleSubject.find_by!(name: "Português")
    b = CycleSubject.find_by!(name: "Constitucional")
    cycle = StudyCycle.find_by!(active: true)
    patch study_cycle_path(cycle), params: {study_cycle: {name: cycle.name, weekly_reference_minutes: 1800}}
    assert_response :redirect
    assert_equal [900, 1080], [a.reload.configured_minutes, b.reload.configured_minutes]
    patch cycle_subject_path(a), params: {cycle_subject: {knowledge_level: 1}}
    assert_equal 900, a.reload.configured_minutes
    patch apply_suggestion_cycle_subject_path(a)
    assert_equal 1157, a.reload.configured_minutes
  end
end
