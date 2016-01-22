require 'scraperwiki'
require 'mechanize'
require 'open-uri'

agent = Mechanize.new
page = agent.get "https://news.ycombinator.com/from?site=youtube.com"

loop do
  items = page.search(".votelinks")
  items.each do |item|
    data = JSON.parse(open("https://hacker-news.firebaseio.com/v0/item/#{item.at("a")[:id].split("_").last}.json").read)
    ScraperWiki.save_sqlite(["id"], data)
    puts "Saving #{data["id"]}"
  end

  puts "\n\n"

  if next_link = page.link_with(text: "More")
    puts "Turning page"
    page = next_link.click
  else
    puts "Done."
    break
  end
end