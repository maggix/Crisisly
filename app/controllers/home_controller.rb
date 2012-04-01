class HomeController < ApplicationController
	
	caches_action :index, :expires_in => 60.seconds, :public => true, :if => Proc.new { !logged_in? && flash.blank? }
	caches_action :login_required, :expires_in => 60.seconds, :if => Proc.new { !logged_in? && flash.blank? }
	caches_action :about, :expires_in => 600.seconds, :if => Proc.new { !logged_in? && flash.blank? }
	def index
		trending = REDIS.lrange("trending", 0, 20).uniq
		@trending = {}
		trending.each do |trend|
			trackers = []
			hsh = Digest::MD5.hexdigest(trend)
			trckrs = REDIS.lrange "tracking:#{hsh}", 0, 10
			trckrs.each do |t|
				trackers << User[t.to_i]
			end
			@trending[trend] = trackers.uniq
		end
		feeds = Rails.cache.fetch("latest_feed", :expires_in => 1.hour) do 
			Feedzirra::Feed.fetch_and_parse(["https://api.twitter.com/1/lists/statuses.atom?slug=breakingnews&owner_screen_name=palafo&per_page=100&page=1&include_entities=true", "https://api.twitter.com/1/lists/statuses.atom?slug=breakingnews&owner_screen_name=palafo&per_page=100&page=2&include_entities=true"])
		end
		@feed = []
		begin
			feeds.each do |k,feed|
				feed.entries.each do |f|
					if f.title.include?("#")
						@feed << f
					end
				end
			end
		rescue
			@feed = []
		end
	end

	def about
		@page_title = "About Crisis.ly"
	end

	def twitter_return
		if !twitter_user.id.blank?
			u = User.find(:twitter_id => twitter_user.id)
			if u.blank?
				u = User.create(:twitter_id => twitter_user.id)
			else
				u = u.first
			end

			temp = twitter_user.to_hash
			temp.delete "id"
			temp.delete "id_str"
			u.update(temp)

			temp = JSON.parse twitter_client.get("/1/users/show.json?user_id=#{twitter_user.id}").body
			logger.info temp

			[:profile_image_url].each do |key|
				u.update(key => temp[key.to_s])
			end

			#u.update(temp)

			u.twitter_key = twitter_oauth.key
			u.twitter_secret = twitter_oauth.secret
			u.twitter_token = twitter_client.token
			u.twitter_token_secret = twitter_client.secret
			u.save

			session[:current_user] = u.screen_name
				
			flash[:notice] = "Welcome #{u.name}! You can now access realtime tweets."
			

		end
		redirect_to "/"
	end
	def login_required
		@page_title = "Login required"
	end
end