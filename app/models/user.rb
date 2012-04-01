class User < Ohm::Model


	attribute :twitter_id
	index :twitter_id

	attribute :listed_count
    attribute :verified
    attribute :notifications
    attribute :time_zone
    attribute :protected
    attribute :follow_request_sent
    attribute :location
    attribute :name
    attribute :default_profile
    attribute :utc_offset
    attribute :followers_count
    attribute :url
    attribute :description

    attribute :default_profile_image
    attribute :statuses_count
    attribute :following
    attribute :friends_count
    attribute :is_translator
    attribute :contributors_enabled
    attribute :geo_enabled
    attribute :favourites_count
    attribute :created_at
    attribute :screen_name
    attribute :show_all_inline_media

    attribute :lang

    attribute :email

    attribute :twitter_key
    attribute :twitter_secret
    attribute :twitter_token
    attribute :twitter_token_secret

    attribute :profile_image_url

    attribute :our_score
    attribute :our_score_updated_at
    attribute :klout_score

    index :screen_name
    index :followers_count
    index :email

    def to_s
    	self.screen_name
    end

    def update_our_score
        if self.our_score_updated_at.blank? || Time.parse(self.our_score_updated_at) < Time.now - 24.hours

            followers = self.followers_count.to_i
            followers = 3000 if followers > 3000

            temp_our_score = (followers.to_f / 30.to_f).to_i

            temp_our_score = temp_our_score + (self.listed_count.to_i * 3)
            temp_our_score = temp_our_score + 25 if self.verified == true || self.verified == "true"
            temp_our_score = temp_our_score - 20 if self.following.to_i > 2000 

            temp_our_score = 100 if temp_our_score > 100
            temp_our_score = 1 if temp_our_score < 1
            self.our_score = temp_our_score


            self.our_score_updated_at = Time.now
            #self.save
        end
    end

    #The score, independant of the person watching
    def pure_score
        self.our_score.to_i
    end


    #when should we expire it from the news feed? (max one minute)
    def expire_in
        60 * 1000 * (self.our_score.to_f/100.to_f)
    end

end