# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'

class TableParserRobot
	attr_accessor :html, :chamber, :lamb, :session, :session_buffer

	def initialize(html)
		@html = html
		@base_url = 'http://www.senado.cl'
		@chamber = 'Senado'
		@lamb = lambda {|session, a| 
			a.push(session)
		}
		@session_buffer = Array.new
	end
	def process
		doc = Nokogiri::HTML(@html, nil, 'utf-8')
		doc.xpath('//*[@id="contentTopI"]/div[1]/div[2]/table//tr[(position()>2)]').each do |tr|
			session = get_table(tr)
			@lamb.call(session, @session_buffer)
		end
		@session_buffer
	end
	def get_table(tr)
		table_url = tr.at_xpath('td[5]/a/@href').to_s.strip
		begin
			url = @base_url+table_url
			puts 'Procesando tabla (URL): '+url
			#file = open(url)
			#table_html = file.read # table_html
			#puts 'table_html: '+table_html
			table_session = get_bills(url)
			if !table_session.nil?
				puts 'El documento es una tabla de sesiones válida'
				#puts '------------->'
				#p table_session
				#puts '<-------------'
				result = table_session
			end
		rescue Exception=>e
		end
		result
	end
	def get_bills(url)
		session = Hash.new
		#exec python script
		table_values = %x[python table_parser.py '#{url}'].gsub(/\n/,' ')
		#puts 'table_values: '+table_values

		if !(table_values.match(/skipped/))
			session['session'] = table_values.scan(/session: (\d*)/).flatten[0]
			session['legislature'] = table_values.scan(/legislature: (\d*)/).flatten[0]
			session['date'] = table_values.scan(/date: (\w*) (\d{2}) (\d{4})/).join(' ')
			session['bills'] = table_values.scan(/bill numbers: (\S*)/).flatten[0].split(/,/)
			session['chamber'] = @chamber

			session
		end
	end
end

if !(defined? Test::Unit::TestCase)
	url = 'http://www.senado.cl/appsenado/index.php?mo=sesionessala&ac=doctosSesion&tipo=27'
	puts '1/3 Descargando la tabla de sesiones de www.senado.cl'
	file = open(url)
	puts '2/3 Procesando el documento...'
	html = file.read
	robot = TableParserRobot.new(html)
	robot.lamb = lambda {|session, a|
		url = 'http://api.ciudadanointeligente.cl/billit/cl/tables'
		a.push(session)
		if !session.nil?
			data = {
				:id => session['legislature'].concat('-'+session['session']),
				:date => session['date'],
				:chamber => session['chamber'],
				:legislature => session['legislature'],
				:session => session['session']
			}
			#puts '<------------'
			#p data
			#puts '------------>'
			RestClient.put url, data, {:content_type => :json}
		end
	}
	resultado = robot.process
	puts '3/3 Finalizado.'
end
