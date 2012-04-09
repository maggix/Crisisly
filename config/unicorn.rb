# config/unicorn.rb
# Set environment to development unless something else is specified
env = ENV["RAILS_ENV"] || "production"

# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
worker_processes (env == 'production' ? 2 : 2)

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
if env == "production"
  listen "/tmp/crisisly.socket", :backlog => 1024
else
  listen 3000
end


# Preload our app for more speed
preload_app true

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

pid "/tmp/unicorn.crisisly.pid"

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# Production specific settings
if env == "production"
  # Help ensure your application will always spawn in the symlinked
  # "current" directory that Capistrano sets up.
  working_directory "/home/ubuntu/crisisly/current"

  # feel free to point this anywhere accessible on the filesystem
  user 'ubuntu'#, 'staff'
  shared_path = "/home/ubuntu/crisisly/shared"

  stderr_path "#{shared_path}/log/unicorn.crisisly.stderr.log"
  stdout_path "#{shared_path}/log/unicorn.crisisly.stdout.log"
end


before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "/tmp/unicorn.crisisly.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # the following is *required* for Rails + "preload_app true",
  

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end