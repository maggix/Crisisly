class ApplicationController < ActionController::Base
  include Twitter::Autolink
  include Twitter::Extractor
	protect_from_forgery

  before_filter :load_site

  def load_site
    @page_title = "Crisis.ly"
    @tweet_text = "Realtime news with authority"
    @tweet_tags = "crisisly"
    @tweet_should_follow = ["crisisly", "serenestudios"]
  end

	def twitter_client
    OAuth::AccessToken.new(twitter_oauth, *session[:twitter_access_token])
  end
   helper_method :twitter_client
  
  def twitter_oauth
    OAuth::Consumer.new Twitter::Login.consumer_key, Twitter::Login.secret,
      :site => Twitter::Login.site
  end
   helper_method :twitter_oauth
  
  def twitter_user
    if session[:twitter_user]
      Hashie::Mash[session[:twitter_user]]
    end
  end
  helper_method :twitter_user
  
  def twitter_logout
    [:twitter_access_token, :twitter_user, :current_user].each do |key|
      session[key] = nil # work around a Rails 2.3.5 bug
      session.delete key
    end
    reset_session
    redirect_to "/"
  end

  def current_user
    return nil if session[:current_user].blank?
    User.find(:screen_name => session[:current_user]).first
  end
  helper_method :current_user

  def login_required
    if current_user.blank?
      redirect_to "/"
      return false
    end
  end

	def logged_in?
	  !current_user.blank?
	end
	helper_method :logged_in?

  def crisisly_link(text)
    html = auto_link(text)
    html = html.gsub("http://twitter.com/search?q=", "/search/")

    html.html_safe
  end
  helper_method :crisisly_link
end
