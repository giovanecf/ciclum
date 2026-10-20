module DashboardHelper
  # Add new phrases here; the selection stays the same throughout each day.
  MOTIVATIONAL_QUOTES = [
    "The fact that you’re still trying, even gently, means something good is still alive in you.",
    "Stop scrolling and get back to your work. You have goals, you have a purpose and you’re here for a reason. The world needs you.",
    "Cheer for the other side, because with out them you would have no one to play with",
    "It takes a ton of humiliation to gain a gram of humility.",
    "To confuse your enemies, you must first confuse yourself (just a joke... sorry)"
  ].freeze

  def daily_motivational_quote
    MOTIVATIONAL_QUOTES[Date.current.jd % MOTIVATIONAL_QUOTES.length]
  end
end
