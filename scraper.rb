require 'scraperwiki'
require 'mechanize'
require 'open-uri'

def scrape_from site
  agent = Mechanize.new
  page = agent.get "https://news.ycombinator.com/from?site=#{site}"

  page_number = 0
  loop do
    puts "Scanning page ##{page_number += 1} for #{site}"
    items = page.search(".votelinks")
    items.each do |item|
      item_id = item.at("a")[:id].split("_").last
      begin
        item_json = JSON.parse(open("https://hacker-news.firebaseio.com/v0/item/#{item_id}.json").read)
        data = {
          :id => item_json["id"],
          :by => item_json["by"],
          :score => item_json["score"],
          :time => item_json["time"],
          :title => item_json["title"],
          :youtube_url => item_json["url"]
        }
        if data[:youtube_url] =~ /(\/watch?)|(youtu.be\/)/
          ScraperWiki.save_sqlite([:id, :youtube_url], data)
          puts "Add #{data[:id]}: #{data[:title]}"
        end
      rescue
        puts "Error: #{item_id}"
        next
      end
    end
    puts "\n"

    if next_link = page.link_with(text: "More")
      page = next_link.click
    else
      puts "Done."
      break
    end
  end
end

threads = []
threads << Thread.new { scrape_from "youtube.com" }
threads << Thread.new { scrape_from "youtu.be" }
threads.each { |thr| thr.join }
