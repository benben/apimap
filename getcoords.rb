#!/usr/local/bin/ruby -w
# coding: utf-8
require 'rubygems'
require 'yaml'
require 'mysql2'
require 'rest_client'
require 'yajl'

begin
  config = YAML.load_file("config.yml")
  # connect to the MySQL server
  db = Mysql2::Client.new(:host => config['mysql_host'], :username => config['mysql_user'], :password => config['mysql_pass'], :database => config['mysql_db'], :port => config['mysql_port'], :socket => config['mysql_sock'], :encoding => "utf8")
  # get server version string and display it
  # puts "Server version: " + db.get_server_info
  #st = db.prepare('INSERT INTO archiv (`date`,`Iac`,`Uac`,`Fac`,`Pac`,`Zac`,`Riso`,`dI`,`Upv-Ist`,`PPV`,`E-Total`,`h-Total`,`h-On`,`Netz-Ein`,`E-Total DC`,`Status`,`Fehler`) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)')
  #st.execute(t[0],t[1],t[2],t[3],t[4],t[5],t[6],t[7],t[8],t[9],t[10],t[11],t[12],t[13],t[15],t[16],t[17])
	firmen = db.query("SELECT id, name, street, housenumber, postcode, city, url_primary FROM data_mediahandbook_companies")
	firmen.each do |f|
		#h = Yajl::Parser.parse(RestClient.get 'http://nominatim.openstreetmap.org/search',:params => {:q => "#{f['Strasse']} #{f['Hausnummer']}, #{f['Ort']}", :format => 'json'}, :user_agent => 'ben at nerdlabor dot de')
		#h = Yajl::Parser.parse(RestClient.get 'http://85.25.67.150/search',:params => {:q => "#{f['Strasse']} #{f['Hausnummer']}, #{f['Ort']}", :format => 'json'}, :user_agent => 'ben at nerdlabor dot de')
		#http://open.mapquestapi.com/nominatim/v1/
	 response = RestClient.get 'http://open.mapquestapi.com/nominatim/v1/search',:params => {:q => "#{f['street']} #{f['housenumber']}, #{f['city']}", :format => 'json'}
		h = Yajl::Parser.parse(response)
		h = h[0]
		
		unless h
			h = {}
		 h['lat'] = ""
		h['lon'] = ""
		h['class'] = ""
		end

		db.query("INSERT INTO `firmen`.`firmen` (`id`,`name`,`street`,`housenumber`,`postcode`,`city`,`website`,`lat`,`lon`,`class`,`json`) VALUES 
							('#{f['id']}','#{f['name']}','#{f['street']}','#{f['housenumber']}','#{f['postcode']}','#{f['city']}','#{f['url_primary']}','#{h['lat']}','#{h['lon']}','#{h['class']}','#{response}');")
		puts "updated #{f['id']} with"
		puts response
		puts
		#sleep 0.5
	end
rescue Mysql2::Error => e
  puts "Error code: #{e.errno}"
  puts "Error message: #{e.error}"
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
#rescue Exception => e
#  puts "Error: #{e}"
ensure
  # disconnect from server
  db.close if db
end
