MOBILE_USER_AGENTS = 'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                          'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                          'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
                          'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                          'webos|amoi|novarra|cdm|alcatel|pocket|ipad|iphone|mobileexplorer|' +
                          'mobile'

module ApplicationHelper
	include Twitter::Extractor
	def is_mobile_device?
		request.user_agent.to_s.downcase =~ Regexp.new(MOBILE_USER_AGENTS)
	end

	# Can check for a specific user agent
	# e.g., is_device?('iphone') or is_device?('mobileexplorer')

	def is_device?(type)
		request.user_agent.to_s.downcase.include?(type.to_s.downcase)
	end
end
