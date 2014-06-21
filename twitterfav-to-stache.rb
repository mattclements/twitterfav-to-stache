#!/usr/bin/env ruby

require 'rubygems'
require 'twitter'
require 'json'
require 'uri'
require 'open-uri'
require 'open_uri_redirections'

file = File.read('config.json')
config_data = JSON.parse(file)

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = config_data["twitter"]["consumer_key"]
  config.consumer_secret     = config_data["twitter"]["consumer_secret"]
  config.access_token        = config_data["twitter"]["access_token"]
  config.access_token_secret = config_data["twitter"]["access_secret"]
end

tweets = client.favorites.to_a

short_urls = Array.new
urls = Array.new

max_tweet_id = config_data["max_tweet_id"]

puts "Retriving Tweets..."
tweets.each { |tweet|

	if(tweet.id>config_data["max_tweet_id"])
		links = URI.extract(tweet.text,/http(s)?|mailto/)

		links.each { |link| short_urls.push(link) }

		if(tweet.id>max_tweet_id)
			max_tweet_id = tweet.id
		end
	end
}


if config_data["max_tweet_id"]!=max_tweet_id
	config_data["max_tweet_id"] = max_tweet_id

	File.open("config.json","w") do |f|
		f.write(JSON.pretty_generate(config_data))
	end
end

if short_urls.empty?
	puts "No Favourite Tweets Available"
	exit 1
end

puts "Converting #{short_urls.count} Short-Links to Full-Links..."
short_urls.each { |url|
	open(url, :allow_redirections => :all) do |resp|
		urls.push(resp.base_uri.to_s)
	end
}

if urls.empty?
	puts "Nothing to Do"
	exit 1
end

puts "Pushing #{urls.count} Links to Stache..."
urls.each { |url|
	system("open", "stache://add-bookmark?url=#{url}")
}
