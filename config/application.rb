require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"
require "sass-rails"


require 'rack/cache'

require File.expand_path('../newsly', __FILE__)

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Newsly
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W(#{config.root}/lib #{config.root}/app/jobs)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true
    #config.assets.compile = false

    config.assets.precompile += %w( modernizr.min.js plugins.js rails.js respond.min.js socket.js jqote.js spin.js style.css )
    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.twitter_login = Twitter::Login.new :consumer_key => TWITTER_CONSUMER, :secret => TWITTER_SECRET

    config.sass.load_paths ||= []
    config.sass.load_paths << "#{Rails.root}/app/assets/stylesheets"
    config.sass.load_paths << "#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"
    config.sass.load_paths << "#{Gem.loaded_specs['html5-boilerplate'].full_gem_path}/stylesheets"
    #if Rails.env == "production" #fuck know's what the problem is here
        #got it. zerodowntime restart doesn't reload bundle exec...
    #    config.sass.load_paths << "/home/ubuntu/shared/bundle/ruby/1.9.1/bundler/gems/compass-recipes-a9df1676f8e2/stylesheets"
    #else    
    config.sass.load_paths << "#{Gem.loaded_specs['compass-recipes'].full_gem_path}/stylesheets"
    #end

    config.assets.debug = false

    config.cache_store = :redis_store, "redis://127.0.0.1:6379/1"

    config.middleware.use Rack::ContentLength
  end
end

#Dir["#{ENV['PWD']}/app/jobs/*.rb"].each { |file| require file }