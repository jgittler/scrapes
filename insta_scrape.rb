require "csv"
require "httparty"
require "nokogiri"
require "pry"
require "ostruct"

class InstaScrape
  attr_accessor :names, :file, :er_cut, :min_f, :max_f, :all, :rejected, :refs, :filter_ref, :ad_refs
  attr_reader :errors, :initial, :unfiltered, :non_defaults

  def initialize(names, file = "insta_data.csv")
    @names = clean_names(names)
    @initial = @names
    @file = file
    @er_cut = 1.25
    @min_f = 7000.0
    @max_f = 80000.0
    @rejected = ["clinic", "store", "apparel", "co.", "inc.", "collective", "clothing", "shop", "eyewear", "sunglasses", "watches", "wallets", "foundation", "magazine"]
    @filter_ref = true
    @ad_refs = ["#ad", "#ads", "advertise", "promo", "collab", "shop"]
    @refs = ["outfit", "style", "eyecare", "charity", "eyewear", "sunglass", "shades", "sunnie", "fashion"]
    @non_defaults = [:@names, :@initial, :@errors, :@all, :@unfiltered, :@non_defaults]
    @errors = []
  end

  def defaults
    puts
    instance_variables.reject { |v| non_defaults.include?(v) }.each { |v| puts "#{v.to_s.split('@').last}: #{instance_variable_get(v)}" }
    puts
  end

  def self.js_script
    puts(<<-EOT)
// adds jQuery
var jq = document.createElement('script');
jq.src = "https://ajax.googleapis.com/ajax/libs/jquery/2.1.4/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(jq);

// add clean() function
Array.prototype.clean = function(deleteValue) { for (var i = 0; i < this.length; i++) {
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
          desc = hash.dig("user", "biography")
          if !desc.nil?
            email = desc.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)
          else
            email = []
          end
          caps = hash.dig("user", "media", "nodes").map { |i| i.dig("caption") }
          { u: n, f: followers, er: ((avg_likes / followers * 100).round(2) rescue 0.0), email: (email.empty? ? "" : email.first), caps: caps }
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
    end.reject { |a| a.class != Hash }

    @unfiltered = @all
  end

  def add_ref(*arr)
    @refs << arr
    @refs.flatten!
  end

  def remove_ref(*arr)
    refs.each do |r|
      if [arr].flatten.include?(r)
        @refs.delete(r)
      end
    end
  end

  def stats
    puts
    puts "Total names: #{initial.count}"
    puts "Total clean names: #{initial.compact.count}"
    puts "Total emails: #{unfiltered.select { |a| !a[:email].empty? }.count}"
    puts "Filtered: #{all.count}" rescue ""
    puts "Total filtered emails: #{all.select { |a| !a[:email].empty? }.count}"
    puts "Total error: #{errors.count}"
    puts
  end

  def includes?(sub_strings, string)
    sub_strings.any? { |s| string.include?(s) }
  end

  def filtered_count
    arr = filter(unfiltered)
    puts arr
    puts "-----------------"
    puts "COUNT: #{arr.count}"
  end

  def filter!
    @all = filter(unfiltered)
  end

  def joined
    all.compact.map do |a|
      [a[:u], a[:f], a[:er], a[:email]]
    end
  end

  private

  def clean_names(names)
    names.map do |n|
      if n.include?("meta property")
        n.split('"')[1]
      else
        n
      end
    end.uniq
  end

  def match_refs?(cap, refs)
    !cap.scan(Regexp.new(refs.join("|"))).empty?
  end

  def filter(arr)
    arr = arr.compact
    arr = arr.reject { |a| a.class != Hash }
    arr = arr.reject {|i| i[:f] < min_f || i[:f] > max_f || i[:er] < er_cut }
    if filter_ref
      arr = arr.select do |a|
        if a.has_key? :caps
          a[:caps].any? do |cap|
            if !cap.nil?
              match_refs?(cap, refs) && match_refs?(cap, ad_refs)
            end
          end
        else
          false
        end
      end
    end
    arr
  end
end
