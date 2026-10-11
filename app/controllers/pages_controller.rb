class PagesController < ApplicationController
  skip_before_action :require_login, :ensure_default_cycle

  def about
  end
end
