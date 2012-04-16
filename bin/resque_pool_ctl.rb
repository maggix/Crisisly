require 'rubygems'
require 'daemons'

dir = File.dirname(__FILE__)
if ENV['RAILS_ENV'] == "production"
	Daemons.run(dir + '/resque_pool.rb', {:log_output => true, :multiple => false, :log_dir => "/home/ubuntu/crisisly/shared/log", :dir_mode => :normal, :dir => '/home/ubuntu/crisisly/shared/pids'})
else
	Daemons.run(dir + '/resque_pool.rb', {:log_output => true, :multiple => false, :log_dir => ".", :dir_mode => :script, :dir => '.'})
end