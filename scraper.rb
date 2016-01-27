require 'scraperwiki'
require 'mechanize'
require 'open-uri'

def get_youtube_id url
  begin
    id = (url.include? "youtube.com/watch") ? url.split("/").last.split("?").last.split("&").first.split("=").last : url.split("/").last
    return id
  rescue
    return nil
  end
end

def scrape_from site
  agent = Mechanize.new
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
      ScraperWiki.save_sqlite([:id], data) unless data[:youtube_id].nil?
      puts "Add #{data[:id]}: #{data[:title]}"
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

scrape_from "youtube.com"
scrape_from "youtu.be"
