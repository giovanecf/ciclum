module DashboardHelper
  # Add new phrases here; the selection stays the same throughout each day.
  MOTIVATIONAL_QUOTES = [
    "The fact that you’re still trying, even gently, means something good is still alive in you."
  ].freeze

  def daily_motivational_quote
    MOTIVATIONAL_QUOTES[Date.current.jd % MOTIVATIONAL_QUOTES.length]
  end
end
