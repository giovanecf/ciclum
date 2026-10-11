class EffortRanking
  Level = Struct.new(:name, :minutes, keyword_init: true)

  LEVELS = [
    Level.new(name: '"Meta"', minutes: 180),
    Level.new(name: "Meta Iniciante", minutes: 360),
    Level.new(name: 'Meta “Estudo muito”', minutes: 720),
    Level.new(name: "Meta Seriedade", minutes: 1440),
    Level.new(name: "Meta Competitiva", minutes: 2160),
    Level.new(name: "Meta Desempregada", minutes: 2880),
    Level.new(name: "Meta Caverna", minutes: 3240),
    Level.new(name: "Meta Lendária", minutes: 3600)
  ].freeze

  COLORS = %w[#e3bc00 #54a72b #10a999 #4578dc #6651d8 #8b4bd1 #c13dbd #273248].freeze

  attr_reader :weekly_minutes

  def initialize(weekly_minutes)
    @weekly_minutes = weekly_minutes.to_i
  end

  def levels = LEVELS
  def current_level = LEVELS.select { |level| weekly_minutes >= level.minutes }.last
  def next_level = LEVELS.find { |level| weekly_minutes < level.minutes }
  def title = current_level&.name || "Em construção"

  def progress_percent
    following = next_level
    return 100 unless following
    previous_minutes = current_level&.minutes || 0
    ((weekly_minutes - previous_minutes) * 100.0 / (following.minutes - previous_minutes)).round.clamp(0, 100)
  end

  def level_percent(level)
    (weekly_minutes * 100.0 / level.minutes).round.clamp(0, 100)
  end

  def color_for(index) = COLORS.fetch(index)
  def reached?(level) = weekly_minutes >= level.minutes
end
