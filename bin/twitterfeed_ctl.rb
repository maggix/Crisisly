require 'rubygems'
require 'daemons'

dir = File.dirname(__FILE__)

Daemons.run(dir + '/twitterfeed.rb', {:log_output => true, :multiple => false, :log_dir => "/home/ubuntu/crisisly/shared/log", :dir_mode => :normal, :dir => '/home/ubuntu/crisisly/shared/pids'})