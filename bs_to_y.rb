require "csv"
require "json"
require "active_support/inflector"

class BStoY
  attr_reader :fr, :fd, :names

  def initialize(file_to_read, file_to_download)
    @fr = file_to_read
    @fd = file_to_download
    @names = CSV.read("./names.csv").flatten
  end

  def download
    CSV.open( fd, 'w' ) do |writer|
      with_names.each do |i|
        writer << i
      end
    end
  end

  def includes?(sub_strings, string)
    sub_strings.any? { |s| string.include?(s) }
  end

  def c_data(data)
    data.map do |i|
      i.compact.map.with_index do |o, idx|
        unless includes?(["email", "domain", "example"], o)
          o if (o.include?("@") || idx < 2)
        end
      end.compact
    end[1..-1]
  end

  def with_names
    data = CSV.read(fr)
    c_data(data).each do |i|
      max = i.count - 1
      i.each_with_index do |o, idx|
        gets = []
        if o.include?("@")
          try = o.split("@").first
          if names.include?(try.capitalize)
            i.unshift(try.capitalize)
            i.insert(3, o)
            gets << "1"
            break
          end
          if gets.empty? && idx == max
            if i.include?(".")
              i.unshift(i.first.split(" ").first)
            else
              i.unshift(i.first.split(" ").first(2).join(" "))
            end
            break
          end
        end
        if gets.empty? && idx == max
          i.unshift("")
          break
        end
      end
    end
  end
end
