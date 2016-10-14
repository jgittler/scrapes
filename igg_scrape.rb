require "csv"
require "json"
require "active_support/inflector"

class IGGScrape
  attr_reader :sites, :camps, :money, :file

  def initialize(sites, money, camps, file = "igg_data.csv")
    @sites = sites
    @money = money
    @camps = camps
    @file = file
  end

  def self.js_script
    puts(<<-EOT)
var cards = $(".ng-scope.ng-isolate-scope a”);

var paths = [];
$.each(cards, function() { paths.push($(this).attr("ng-href")) });

var baseUrl = "https://www.indiegogo.com”;
responses = [];
$.each(paths, function() {
  var url = baseUrl + this;
  responses.push($.ajax({ url: url, method: "GET", headers: {  'Access-Control-Allow-Origin':  }}))
});

strings = [];
$.each(responses, function() { strings.push(this.responseText) });

sites = [];
$.each(strings, function() {
  var idxOne = this.indexOf('"websites":');
  var idxTwo = this.indexOf('bank_account_country');
  sites.push(this.substring(idxOne, idxTwo));
});

// to set sites in irb
console.log(JSON.stringify(sites))

// to set money in irb
money = [];
$.each($(".discoveryCard-balance"), function() { money.push($(this).html()); });
console.log(JSON.stringify(money))

// to set camps in irb
camps = [];
$.each(paths, function() { camps.push(this.split("/")[2]) });
console.log(JSON.stringify(camps))
    EOT
  end

  def download
    CSV.open( file, 'w' ) do |writer|
      joined.each do |i|
        writer << i.split(',')
      end
    end
  end

  def joined
    clean_camps.zip(clean_money).zip(clean_sites).map { |i| i.join(",") }.select { |i| i.include?("$") }
  end

  def clean_sites
    site_groups.map { |a| a if !a.empty? }.compact
  end

  def site_groups
    sites.map { |a| JSON.parse(a.slice(a.index("[")..-3)) }
  end

  def clean_money
    clean(money.map.with_index do |m, idx|
      if !clean_sites[idx].nil?
        m
      end
    end)
  end

  def clean_camps
    clean(camps.map.with_index do |c, idx|
      if !clean_sites[idx].nil?
        c
      end
    end).map(&:titleize)
  end

  def clean(arr)
    arr.compact.map { |i| i.delete(",") }
  end
end
