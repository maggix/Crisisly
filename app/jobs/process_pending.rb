class ProcessPending
  include Twitter::Autolink
  include Twitter::Extractor
  @queue = :pending_tweet

  def self.perform(id)
    pt = PendingTweet[id]

    return if pt.blank?

    #Process it 

    #who's subscribed?
    redis = Resque.redis
    redis.namespace = nil
    redis.quit
    redis
    
    begin
        data = {}

        data["text"] = pt.text
        data["html"] = Twitter::Autolink.auto_link(pt.text).gsub("http://twitter.com/search?q=", "/search/")
        data["account"] = pt.user_screen_name

        #This will have been created by set score
        user = User.find(:screen_name => pt.user_screen_name).first
        if user.blank?
            user = User.new 
            user.screen_name = pt.user_screen_name
            #user.save Don't actually commmit this to memory - takes up too much for now.
        end
        user.profile_image_url = pt.user_profile_image_url
        
        user.url = pt.user_url 
        user.favourites_count = pt.user_favourites_count
        user.screen_name = pt.user_screen_name
        user.description = pt.user_description
        user.location = pt.user_location
        user.geo_enabled = pt.user_geo_enabled
        user.friends_count = pt.user_friends_count
        
        user.listed_count = pt.user_listed_count
        user.verified = pt.user_verified
        user.following = pt.user_following
        user.created_at = pt.user_created_at
        user.name = pt.user_name
        user.statuses_count = pt.user_statuses_count
        user.followers_count = pt.user_followers_count
        user.profile_image_url = pt.user_profile_image_url
        user.twitter_id = pt.user_id
        
        user.update_our_score
        #user.save

        #Update the score depending on the tweet itself
        tweet_score = user.pure_score
        tweet_score = (tweet_score.to_f / 8.to_f).to_i if pt.text.match(/^RT/) != nil #RTs aren't news, or live
        tweet_score = tweet_score - 15 if pt.text.match(/^@/)

        tweet_score = tweet_score + 10 if pt.retweet_count.to_i > 20

        word_count = pt.text.split.count

        #Language analysis
        tweet_score = tweet_score - 20 if pt.text.length > 50 && (pt.text.count('!@\:)(*;').to_f/pt.text.length.to_f) > 0.05.to_f
        tweet_score = tweet_score - 10 if word_count < 8
        tweet_score = tweet_score + 10 if word_count >= 11


        tweet_score = 100 if tweet_score > 100
        tweet_score = 1 if tweet_score < 1


        data["imgurl"] = user.profile_image_url
        data["pure_score"] = tweet_score
        data["web_id"] = pt.web_id
        data["expire_in"] = user.expire_in
        data["geo"] = pt.coordinates
        

        qtag = Digest::MD5.hexdigest(pt.response_key)
        channel = Digest::MD5.hexdigest("#{pt.response_user}:#{pt.response_key}")
        channel_guest = Digest::MD5.hexdigest("guest:#{pt.response_key}")
        json = data.to_json
        pt.delete
        redis.pipelined do 
            #lets tell our specific user
            redis.publish channel, json
            #lets tell any quests
            redis.publish channel_guest, json
            #lets archive it for later
            redis.lpush "archive:#{qtag}", json
            redis.expire "archive:#{qtag}", 2.weeks
        end

    rescue Exception => e
        Rails.logger.error e.backtrace
        pt.delete
    end
    
  end
end