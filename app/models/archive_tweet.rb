class ArchiveTweet
	attr_accessor :web_id, :account, :imgurl, :pure_score, :text, :html, :expire_in, :geo

	def initialize(json)
		data = JSON.parse(json)
		data.each do |k,v|
			self.send("#{k}=", v)
		end
	end
end