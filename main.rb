#!/usr/bin/env ruby

require 'rubygems'
require 'commander/import'
require 'nokogiri'
require 'date'
require 'open-uri' # Required to download the photo
require "net/http"
require 'tempfile'
require 'ostruct'

program :version, '0.0.1'
program :description, 'combine bbc downloads'
 
command :munger do |c|
  c.syntax = 'bbcmetamunger munger [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--convert', 'use handbrakecli to convert to AppleTV2'
  c.option '--deleteorig', 'if converting, delete original'
  c.action do |args, options|
    # Do something or c.when_called Bbcmetamunger::Commands::Munger
    options.default :convert => false
    options.default :deleteorig => false
    
    files = args.clone
    files.reject! {|e| !e.end_with?("mp4")}
    files.each do |file|
      xmlfile = file.gsub(/mp4$/,"xml")
      f = File.open(xmlfile)
      doc = Nokogiri::XML(f)
      f.close

      doc.remove_namespaces!
      
      metadata = OpenStruct.new
      
      
      # get the things we want
      metadata.channel = doc.xpath("//channel").text
      metadata.descmedium = doc.xpath("//descmedium").text
      metadata.desclong = doc.xpath("//desc").text
      metadata.title = doc.xpath("//title").text
      metadata.longname = doc.xpath("//longname").text
      metadata.firstbcast = doc.xpath("//firstbcast").text
      metadata.thumbnail = doc.xpath("//thumbnail6").text
      metadata.senum = doc.xpath("//senum").text
      if metadata.senum
        metadata.senum[/s(\d{2})e(\d{2})/]
        metadata.season = $1
        metadata.episode = $2
      else
        d = DateTime.parse metadata.firstbcast
        metadata.season = d.year
        metadata.episode = d.cweek
      end
      metadata.category = doc.xpath("//categories").text.split(",").first
      
      # mediatype 9 is movie, 10 is tv
      metadata.mediatype = doc.xpath("//categories").text.split(",").include?("Films") ? 9 : 10

      
      if metadata.thumbnail
        url = URI.parse(metadata.thumbnail)
        Net::HTTP.start(url.host, url.port) {|http|
           resp = http.get(url.path)
           tempfile = Tempfile.new('test.jpg')
           File.open(tempfile.path, 'wb') do |f|
             f.write resp.body
           end
           metadata.thumbnail_file = tempfile unless resp.nil?
         }
      end
      
      if options.convert
        `HandBrakeCLI -i #{file} -o #{file.gsub(/mp4$/, '.m4v')} -Z "AppleTV 2"`
        if options.deleteorig
          `rm #{file}`
        end
        file = file.gsub(/mp4$/, '.m4v')
      end
      
      p "mp4tags -network '#{metadata.channel}' -description '#{metadata.descmedium}' -type #{metadata.mediatype} -genre '#{metadata.category}' -song '#{metadata.title}' -artist '#{metadata.longname}' -show '#{metadata.longname}' #{file}"
      `mp4tags -network '#{metadata.channel}' -description "#{metadata.descmedium}" -type #{metadata.mediatype} -genre '#{metadata.category}' -song "#{metadata.title}" -artist "#{metadata.longname}" -show "#{metadata.longname}" -episode #{metadata.episode} -year #{metadata.firstbcast} -season #{metadata.season} -longdesc "#{metadata.desclong}" #{file}`
      
      if metadata.thumbnail_file
        p "mp4art --add #{metadata.thumbnail_file.to_path} #{file}"
        `mp4art --add #{metadata.thumbnail_file.to_path} #{file}`
      end
    end
  end
end