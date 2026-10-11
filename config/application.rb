require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)
module Ciclum
  class Application < Rails::Application
    config.load_defaults 8.1
    config.time_zone = "America/Sao_Paulo"
    config.i18n.default_locale = :'pt-BR'
    config.active_record.default_timezone = :local
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
