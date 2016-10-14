require "httparty"
require "csv"
require "nokogiri"

class KSScrape
  attr_reader :urls, :sites, :backers, :money

  def initialize(urls, file = 'ks_data.csv')
    @urls = urls
    @sites = []
    @backers = []
    @money = []
    @file = file
  end

  def self.js_script
    puts(<<-EOT)
var cards = $('.project-profile-feature-image a');
var urls = [];
$.each(cards, function() { urls.push($(this).attr("href")) });

// to set urls in irb
console.log(JSON.stringify(urls))
    EOT
  end

  def download
    create_rows

    joined = sites.zip(clean(money)).zip(clean(backers)).map{|i| i.join(",") }
    CSV.open( file, 'w' ) do |writer|
      joined.each do |i|
        writer << i.split(",")
      end
    end
  end

  def clean(arr)
    arr.map { |i| i.delete(",") }
  end

  def create_rows
    urls.map do |i|
      body = HTTParty.get(URI('https://www.kickstarter.com' + i.split('https://www.kickstarter.com').last)).body
      btn = Nokogiri::HTML(body).css('.project-profile__button_container')
      if btn.count > 0
        link = btn.children.select {|i| i.name == 'a' }.first
        if link.count > 0
          href = link.attributes['href'].value
          if !href.downcase.include?('kickstarter')
            stats = Nokogiri::HTML(body).css('.NS_campaigns__spotlight_stats').children
            cash = stats.select {|i| i.name == 'span' }.first.children.text
            if cash.include?("$")
              sites << link.attributes['href'].value
              backers << stats.select {|i| i.name == 'b' }.first.children.text.split(' ').first
              money << cash
            end
          end
        end
      end
    end
  end
end
