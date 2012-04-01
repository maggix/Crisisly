ENV['RAILS_ENV'] ||= 'production'
require File.join(File.dirname(__FILE__), '..', 'config', 'environment.rb')

RESQUE_POOL_CONFIG = File.join(Rails.root, "config", "resque-pool.yml")
ENV['RESQUE_POOL_CONFIG'] = RESQUE_POOL_CONFIG

Resque.after_fork do |job|
  
end
Resque::Pool.run