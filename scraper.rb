require 'scraperwiki'
require 'mechanize'
require 'open-uri'
require 'addressable/uri'

def get_youtube_id url
  uri = Addressable::URI.parse url
  if uri.path == "/watch"
    uri.query_values["v"] if uri.query_values
  else
    uri.path
  end
end

def scrape_from site
  page = agent.get "https://news.ycombinator.com/from?site=#{site}"

  loop do
    items = page.search(".votelinks")
    items.each do |item|
      item_json = JSON.parse(open("https://hacker-news.firebaseio.com/v0/item/#{item.at("a")[:id].split("_").last}.json").read)
      data = {
        :id => item_json["id"],
        :by => item_json["by"],
        :score => item_json["score"],
        :time => item_json["time"],
        :title => item_json["title"],
        :youtube_id => get_youtube_id(item_json["url"])
      }
      ScraperWiki.save_sqlite([:id], data)
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
end

agent = Mechanize.new
scrape_from "youtube.com"
scrape_from "youtu.be"