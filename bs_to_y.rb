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

  def with_names
    data = CSV.read(fr)
    c_data = data.map { |i| i.compact.map.with_index { |o, idx| o if (o.include?("@") || idx < 2) }.compact }[1..-1]
    c_data.each do |i|
      max = i.count - 1
      i.each_with_index do |o, idx|
        gets = []
        if o.include?("@")
          try = o.split("@").first
          puts try
          if names.include?(try.capitalize)
            i.unshift(try.capitalize)
            gets << "1"
            break
          end
          if gets.empty? && idx == max
            i.unshift(i.first.split(" ").first(2).join(" "))
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
