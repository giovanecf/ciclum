module DashboardHelper
  # Add new phrases here; the selection stays the same throughout each day.
  MOTIVATIONAL_QUOTES = [
    "The fact that you’re still trying, even gently, means something good is still alive in you.",
    "Stop scrolling and get back to your work. You have goals, you have a purpose and you’re here for a reason. The world needs you."
  ].freeze

  def daily_motivational_quote
    MOTIVATIONAL_QUOTES[Date.current.jd % MOTIVATIONAL_QUOTES.length]
  end
end
