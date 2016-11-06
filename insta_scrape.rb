require "csv"
require "httparty"
require "nokogiri"
require "pry"
require "ostruct"

class InstaScrape
  attr_accessor :names, :file, :er_cut, :min_f, :max_f, :all, :rejected
  attr_reader :errors, :initial

  def initialize(names, file = "insta_data.csv")
    @names = names
    @initial = names
    @file = file
    @er_cut = 2.0
    @min_f = 10000.0
    @max_f = 80000.0
    @rejected = ["clothing", "shop", "eyewear"]
    @errors = []
  end

  def self.js_script
    puts(<<-EOT)
// adds jQuery
var jq = document.createElement('script');
jq.src = "https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js"; document.getElementsByTagName('head')[0].appendChild(jq);

// add clean() function
Array.prototype.clean = function(deleteValue) {
  for (var i = 0; i < this.length; i++) {
    if (this[i] == deleteValue) {         
      this.splice(i, 1);
      i--;
    }
  }
  return this;
};

// Get tile ids for ajax
var ids = [];
$.each($("._8mlbc._t5r8b"), function() {
  ids.push($(this).attr("href").split("/")[2]);
});

// Get responses
var responses = [];
$.each(ids, function(id) {
  responses.push(
    $.ajax({
      url: "https://www.instagram.com/p/" + this + "/",
      method: "GET"
    })
  );
});

wait...

// Get usernames
var names = [];
$.each(responses, function() {
  try {
    var str = this.responseText;
    s1 = str.indexOf("See this Instagram photo by");
    if (s1 < 0) {
      s1 = str.indexOf("See this Instagram video by");
    }
    s2 = str.indexOf("•");
    names.push(str.substring(s1, s2).split("@")[1].trim());
  } catch (e) {
    console.log(e)
  }
});

// print array
console.log(JSON.stringify(names.clean(null)))
    EOT
  end

  def download
    CSV.open( file, 'w' ) do |writer|
      joined.each do |i|
        writer << i
      end
    end
  end

  def collect_all
    @all = names.map do |n|
      next if includes?(rejected, n)
      r = HTTParty.get(URI.decode("https://www.instagram.com/" + n)) rescue OpenStruct.new(code: 500, success?: false)
      if r.success?
        doc = Nokogiri::HTML(r)
        json = JSON.parse(doc.css("body script").map {|i| i if !i.attributes["type"].nil? }.compact.first.children.first.text[21..-1].delete(";"))
        info = json.dig("entry_data", "ProfilePage")
        if !info.nil?
          hash = info.first
          followers = hash.dig("user", "followed_by", "count")
          posts = hash.dig("user", "media", "nodes")
          avg_likes = posts.map {|i| i["likes"]["count"]}.reduce(:+) / posts.count.to_f rescue 1
          { u: n, f: followers, er: (avg_likes / followers * 100).round(2) }
        else
          puts
          puts "missing profile page"
          puts "entry_data: #{json.dig("entry_data")}"
          puts "full json: #{json}"
          puts
        end
      else
        puts
        puts "falied request, code: #{r.code}"
        puts "for username: #{n}"
        puts
        @errors << n
      end
    end
  end

  def stats
    puts
    puts "Total names: #{initial.count}"
    puts "Total clean names: #{initial.compact.count}"
    puts "Filtered: #{all.count}"
    puts "Total error: #{errors.count}"
    puts
  end

  def includes?(sub_strings, string)
    sub_strings.any? { |s| string.include?(s) }
  end

  def filtered_count
    filter(all).count
  end

  def filter!
    @all = filter(all)
  end

  def joined
    all.compact.map { |a| [a[:u], a[:f], a[:er]] }
  end

  private

  def filter(all)
    all.compact.reject {|i| i[:f] < min_f || i[:f] > max_f || i[:er] < er_cut }
  end
end
