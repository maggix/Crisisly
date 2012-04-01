require 'digest/md5'

class SearchController < ApplicationController
	
	def router
		if !params[:q].blank?
			redirect_to search_path(params[:q]), :status => 301
		else
			redirect_to root_path
		end
	end

	def search

		@q = params[:q]
		@q = @q.strip
		@page_title = "#{@q}<span class='title-extra'> - Crisis.ly</span>".html_safe
		@qtag = Digest::MD5.hexdigest(@q)
		@old_tweets = REDIS.lrange "archive:#{@qtag}", 0, 40

		@tweet_text = "Get realtime news, filtered for accuracy"
   		@tweet_tags = "crisisly," + @q.gsub("#", "")
    	
		@template = File.open(Rails.root + "app/views/search/_tweet.html.erb", "rb").read

		@template = @template.gsub(".html_safe", "")
		if logged_in?

			@node_channel = Digest::MD5.hexdigest("#{current_user.to_s}:#{@q}")

			
			#Lets get this user tracking it.
			REDIS.setex "track:#{current_user.to_s}:#{@qtag}", 3.minutes, @q

			REDIS.setex "track:___keepalive:#{current_user.to_s}", 3.minutes, "yes"
			REDIS.setex "track:___changed:#{current_user.to_s}", 3.minutes, "yes"
			#Lets add it to our currently being tracked list
			REDIS.lpush "trending", @q
			
			#Lets add this user to the people tracking it
			REDIS.lpush "tracking:#{@qtag}", current_user.id
			#Lets issue a pub notice to our users channel to make sure we have a worker forked
			REDIS.publish "workers", current_user.to_s

		else
			#if no old tweets, redirect to the login page
			if @old_tweets.blank?
				redirect_to login_required_path
			end

			@node_channel = Digest::MD5.hexdigest("guest:#{@q}")
		end
		

	end

	def keepalive
		@q = params[:q]
		@q = @q.strip

		@qtag = Digest::MD5.hexdigest(@q)
		REDIS.setex "track:#{current_user.to_s}:#{@qtag}", 3.minutes, @q

		REDIS.setex "track:___keepalive:#{current_user.to_s}", 3.minutes, "yes"

		render :text => "ok"
	end
end