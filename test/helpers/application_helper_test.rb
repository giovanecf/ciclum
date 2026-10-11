require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "hour labels follow compact Brazilian formatting" do
    assert_equal "1 h", formatted_hours(60)
    assert_equal "1,5 h", formatted_hours(90)
    assert_equal "1,25 h", formatted_hours(75)
    assert_equal "0,5 h", formatted_hours(30)
    assert_equal "0 h", formatted_hours(0)
  end
end
