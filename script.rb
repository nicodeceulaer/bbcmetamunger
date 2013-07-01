`brew install mp4v2 ffmpeg`

require 'nokogiri'
require 'date'

# read file
fname = ARGV[0]
f = File.open(fname)
doc = Nokogiri::XML(f)
f.close

# remove namespaces
doc.remove_namespaces!

# get the things we want
channel = doc.xpath("//channel").text
descmedium = doc.xpath("//descmedium").text
desclong = doc.xpath("//desc").text
title = doc.xpath("//title").text
longname = doc.xpath("//longname").text
firstbcast = doc.xpath("//firstbcast").text
thumbnail6 = doc.xpath("//thumbnail6").text
senum = doc.xpath("//senum").text
category = doc.xpath("//categories").text.split(",").first

d = DateTime.parse firstbcast
year = d.year

p "Channel: #{channel}"
p "descmedium #{descmedium}"
p "title: #{title}"
p "longname: #{longname}"
p "firstbcast: #{firstbcast}"
p "thumbnail6: #{thumbnail6}"
p "Year: #{year}"
p "senum: #{senum}"
p "category: #{category}"
p "desclong: #{desclong}"
