require 'scraperwiki'
require 'mechanize'
require 'open-uri'

agent = Mechanize.new
page = agent.get "https://news.ycombinator.com/from?site=youtube.com"

loop do
  items = page.search(".votelinks")
  items.each do |item|
    item_json = JSON.parse(open("https://hacker-news.firebaseio.com/v0/item/#{item.at("a")[:id].split("_").last}.json").read)
    ScraperWiki.save_sqlite(["id"], item_json)
  end
  puts "\n\n"
  if next_link = page.link_with(text: "More")
    page = next_link.click
  else
    break
  end
end