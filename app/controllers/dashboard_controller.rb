class DashboardController < ApplicationController
  def show
    @cycle = active_cycle
    @progress = @cycle.progress
    @subjects = @cycle.cycle_subjects.available.order(:position, :id)
    @totals = @cycle.studied_totals
    @ranking = EffortRanking.new(@totals[:week])
  end
end
