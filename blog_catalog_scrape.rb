require "httparty"
require "csv"
require "nokogiri"

class BlogCatalogScrape
  BASE_URL = "https://www.blogcatalog.com"

  attr_reader :file, :start, :finish

  def initialize(start, finish, file = 'blog_catalog_data.csv')
    @start = start
    @finish = finish
    @file = file
  end

  def download
    CSV.open( file, 'a+' ) do |writer|
      joined.each do |i|
        writer << i.split(',')
      end
    end
  end

  def joined
    (start..finish).to_a.flat_map do |idx|
      doc = Nokogiri::HTML(HTTParty.get("#{BASE_URL}/category/fashion/#{idx}"))
      path_arr = doc.css("h3 a")
      paths = path_arr.map { |i| i.attributes["href"].value }
      pages = paths.map { |i| Nokogiri::HTML(HTTParty.get(BASE_URL + i)) }
      pages.map do |i|
        site_arr = i.css("#b_url")
        site_arr.first.attributes["href"].value
      end
    end
  end
end
