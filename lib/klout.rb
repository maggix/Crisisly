class Klout
	def initialize
	   

	    @config = YAML.load_file(File.join(Rails.root, '/config/klout.yml'))[Rails.env]


		@base_url = @config["base_url"]
	    @key = @config["key"]
	    

	    @connection = Faraday.new(:url => @base_url, :ssl => {:ca_path => "/etc/ssl/certs"}) do |builder|
	      builder.request  :url_encoded
	      builder.adapter  :net_http
	    end

	end

	def score(payload)
		payload.merge!({ :key => @key })

    	res = @connection.get do |req|
    		req.url '/1/klout.json'
    		payload.each do |k,v|
    			req.params[k] = v
    		end
	    end

	    res = MultiJson.decode res.body
	    res["users"]
	end
end