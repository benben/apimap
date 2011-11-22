#!/usr/bin/env ruby

require 'rubygems'
require 'rest_client'
require 'json'

API_KEY = '...'

head = File.read("head.html")
foot = File.read("foot.html")

begin
  more_data = true
  chunk_size = 100
  offset = 0
  
  output = {}

  while more_data
    puts "requesting chunk ##{offset} ..."
    response = RestClient.get 'http://www.apileipzig.de/api/v1/mediahandbook/companies', :params => {:api_key => API_KEY, :limit => chunk_size, :offset => offset}
    j = JSON.parse response
    if j['data'].size > 0
      puts "requesting location ##{offset} ..."
      j['data'].each do |company|
        mapres = RestClient.get 'http://open.mapquestapi.com/nominatim/v1/search',:params => {:q => "#{company['street']} #{company['housenumber']}, #{company['city']}", :format => 'json'}
        h = JSON.parse(mapres)
		    h = h[0]
        
        if h
          puts "adding company '#{company['name']}' ..."
          output[[h['lat'], h['lon']]] = [] if output[[h['lat'], h['lon']]].nil?
          output[[h['lat'], h['lon']]] << company
        else
          puts "no address found."        
        end
      end
      offset += chunk_size
    else
      more_data = false
    end
  end

  puts "building html..."
  str = ""
  output.each do |location, companies|
    str += "var markerLocation = new L.LatLng(#{location[0]}, #{location[1]}), marker = new L.Marker(markerLocation); map.addLayer(marker);"
    c = ""
    companies.each do |company|
      if company['url_primary'] != ""
        c += "<a href=\"#{company['url_primary']}\">#{company['name']}</a><br /><br />"
      else
        c += "#{company['name']}<br /><br />"
      end
    end
    str += "marker.bindPopup('#{c[0..-13]}');\n"
  end

  puts "writing file..."
  f = File.new("map.html",  "w+")

  f.write head + str + foot
  f.close

rescue Exception => e
  puts "Error: #{e}"
end

