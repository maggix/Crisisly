class PendingTweet < Ohm::Model
	attribute :in_reply_to_user_id_str
    attribute :text
    attribute :contributors
    attribute :geo 
    attribute :in_reply_to_status_id 
    #:entities=>{:user_mentions=>[], :hashtags=>[], :urls=>[]}, 
    attribute :coordinates 
    attribute :favorited 
    attribute :truncated 
    attribute :source
    attribute :id_str 
    attribute :place
    attribute :retweet_count
    attribute :in_reply_to_screen_name
    attribute :retweeted
    attribute :in_reply_to_user_id 
    attribute :created_at
    attribute :in_reply_to_status_id_str
    attribute :user_url
    attribute :user_favourites_count
    attribute :user_screen_name
    attribute :user_description
    attribute :user_location
    attribute :user_geo_enabled
    attribute :user_friends_count
    attribute :user_id_str
    attribute :user_listed_count
    attribute :user_verified
    attribute :user_following
    attribute :user_created_at
    attribute :user_name
    attribute :user_statuses_count
    attribute :user_followers_count
    attribute :user_profile_image_url
    attribute :user_id
    #attribute :id

    attribute :response_key
    attribute :response_user

   
    #used in the html to track the tweet
    def web_id
        Digest::MD5.hexdigest("#{self.user_screen_name}:#{self.id}:#{self.id_str}")
    end



end