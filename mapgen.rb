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
  sub_market_counts = {}
  sub_market_counts["\"all\""] = 0
  str = ""
  output.each do |location, companies|
    branch = companies[0]['sub_market_id'] ? companies[0]['sub_market_id'] - 1  : 0
    str += "var markerLocation = new L.LatLng(#{location[0]}, #{location[1]}), marker = new L.Marker(markerLocation, {icon: icon_#{"%02d" % branch}}); map.addLayer(marker);"
    c = ""
    companies.each do |company|
      b = "\"%02d\"" % (company['sub_market_id'] ? company['sub_market_id'] - 1  : 0)
      if sub_market_counts.has_key? b
        sub_market_counts[b] += 1
      else
        sub_market_counts[b] = 1
      end
      sub_market_counts["\"all\""] += 1
      c += "<h3>#{company['name']}</h3>"
      c += "<p>#{company['street']} #{company['housenumber']}"
      c += "#{company['housenumber_additional']}" if company['housenumber_additional'] != "" and company['housenumber_additional'] != nil
      c += "<br>"
      c += "#{company['postcode']} #{company['city']}"
      c += "<br><br>E-Mail: #{company['email_primary']}" if company['email_primary'] != "" and company['email_primary'] != nil
      c += "<br>WWW: <a href=\"#{company['url_primary']}\">#{company['url_primary']}</a>" if company['url_primary'] != "" and company['url_primary'] != nil
      c += "</p>"
    end
    str += "marker.bindPopup('#{c}');\n"
    str += "$('div.leaflet-shadow-pane img:last-child').addClass('#{"%02d" % branch}');\n"
    str += "$('div.leaflet-marker-pane img:last-child').addClass('#{"%02d" % branch}');\n"
  end

  str += "var sub_market_counts = {#{sub_market_counts.to_a.map!{|e|e.join(':')}.join(',')}};\n"

  puts "writing file..."
  f = File.new("map.html",  "w+")

  f.write head + str + foot
  f.close

rescue Exception => e
  puts "Error: #{e}"
end
