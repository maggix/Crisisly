require 'rubygems'
require 'daemons'
require 'tweetstream'
require 'twitter-text'

require 'hiredis'
require 'redis/connection/hiredis'
require 'redis'
require 'resque'
#require 'resque_scheduler'
require 'ohm'

require File.expand_path('../../app/models/user.rb',  __FILE__)
require File.expand_path('../../app/models/pending_tweet.rb',  __FILE__)
require File.expand_path('../../app/jobs/process_pending.rb',  __FILE__)
require File.expand_path('../../config/newsly.rb',  __FILE__)

def process_exists?(pid)
	begin
	    Process.kill(0, pid.to_i)
	    true
	rescue Errno::EPERM                     # changed uid
	    true
	rescue Errno::ESRCH
	    false      # or zombied
	rescue
	    false
	end
end

Ohm.connect(:url => ENV["REDISCLOUD_URL"])
REDIS = Ohm.redis

REDIS.subscribe "workers" do |on|
	on.subscribe do |channel, subscriptions|
		puts "Now listening on #{channel}..."
	end

	on.unsubscribe do |channel, subscriptions|
		puts "Stopping listening on #{channel}..."
	end

	on.message do |channel, message|
		user = message.strip
		puts "forking for #{user}"
		r = Redis.new

		if !r.get("track:___islive:#{user.to_s}").nil?
			puts "checking pid #{r.get("track:___islive:#{user.to_s}")}"
			if !process_exists?(r.get("track:___islive:#{user.to_s}"))
				r.del("track:___islive:#{user.to_s}")
			else
				#Lets kill the current process so that we can refork with the new keywords. Clumsy, but can't find a way to break TweetStream between tweets
				Process.kill("TERM", r.get("track:___islive:#{user.to_s}").to_i)
				puts "Killed old fork..."
				r.del("track:___islive:#{user.to_s}")
			end
		end
		
		if r.get("track:___islive:#{user.to_s}").nil? #DAN OR the process isn't running any more
			r.del("track:___islive:#{user.to_s}")
			newpid = fork do
				redis = Redis.new
				Ohm.redis = redis
				Resque.redis = redis

				sleep(3)
				at_exit { redis.del("track:___islive:#{user.to_s}")  }

				user = User.find(:screen_name => user).first
				exit if user.nil?


				TweetStream.configure do |config|
				  config.consumer_key = TWITTER_CONSUMER
				  config.consumer_secret = TWITTER_SECRET
				  config.oauth_token = user.twitter_token
				  config.oauth_token_secret = user.twitter_token_secret
				  config.auth_method = :oauth
				  config.parser = :yajl
				end

				#puts TweetStream.oauth_token
				#puts TweetStream.oauth_token_secret
				#puts TweetStream.consumer_key
				#puts TweetStream.consumer_secret

				puts "tracking..."

				

				while redis.get("track:___keepalive:#{user.to_s}") == "yes" do
					keys = []
					redis.keys("track:#{user.to_s}:*").each do |k|
						keys << redis.get(k)
						# Unless someone else is already tracking it?
					end
					puts "tracking #{keys}..."
					redis.del("track:___changed:#{user.to_s}")
					if keys.size == 0
						puts "nothing to track"
						redis.del("track:___keepalive:#{user.to_s}")
					else

						TweetStream::Client.new.track(keys) do |status, client|
							
							pt = PendingTweet.new
							pt.in_reply_to_user_id_str = status.in_reply_to_user_id_str
							pt.text = status.text
							pt.contributors = status.contributors
							pt.geo = status.geo 
							pt.in_reply_to_status_id = status.in_reply_to_status_id 
							pt.coordinates = status.coordinates 
							pt.favorited = status.favorited 
							pt.truncated = status.truncated 
							pt.source = status.source
							pt.id_str = status.id_str 
							pt.place = status.place
							pt.retweet_count = status.retweet_count
							pt.in_reply_to_screen_name = status.in_reply_to_screen_name
							pt.retweeted = status.retweeted
							pt.in_reply_to_user_id =  status.in_reply_to_user_id 
							pt.created_at = status.created_at
							pt.in_reply_to_status_id_str = status.in_reply_to_status_id_str

							pt.user_url = status.user.url
						    pt.user_favourites_count = status.user.favourites_count
						    pt.user_screen_name = status.user.screen_name
						    pt.user_description = status.user.description
						    pt.user_location = status.user.location
						    pt.user_geo_enabled = status.user.geo_enabled
						    pt.user_friends_count = status.user.friends_count
						    pt.user_id_str = status.user.id_str
						    pt.user_listed_count = status.user.listed_count
						    pt.user_verified = status.user.verified
						    pt.user_following = status.user.following
						    pt.user_created_at = status.user.created_at
						    pt.user_name = status.user.name
						    pt.user_statuses_count = status.user.statuses_count
						    pt.user_followers_count = status.user.followers_count
						    pt.user_profile_image_url = status.user.profile_image_url
						    pt.user_id = status.user.id

						    rk = nil
						    keys.each do |g|
						    	if pt.text.include?(g)
						    		rk = g
						    	end
						    end

						    pt.response_key = rk
						    pt.response_user = user.to_s

							pt.save

							

							
							
							Resque.enqueue(ProcessPending, pt.id) unless pt.id.nil?


							#Lets stop tracking if their keepalive is gone
							client.stop if redis.get("track:___keepalive:#{user.to_s}") != "yes"
							#client.stop if redis.get("track:___changed:#{user.to_s}") == "yes"
							
						end
					end
				end
				redis.del("track:___islive:#{user.to_s}")

			end
			r.set("track:___islive:#{user.to_s}", newpid)
			Process.detach(newpid)
			puts "forked #{newpid}"
		else
			puts "#{user} already has a fork"
		end

	end

end