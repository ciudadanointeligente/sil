# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'

class TableParserRobot
	attr_accessor :html, :chamber, :lamb

	def initialize(html)
		@html = html
		@base_url = 'http://www.senado.cl'
		@chamber = 'Senado'
		@lamb = lambda {|session, a| 
			a.push(session)
		}
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
			file = open(url)
			table_html = file.read
			table_session = get_bills(table_html)
			result = result.merge(table_session)
		rescue Exception=>e
		end	
		result
	end
	def get_bills(table_html = @html)
		#llamar al metodo python, pasarle la url de la tabla
		#y mapear los valores a un hash
	end
end

if !(defined? Test::Unit::TestCase)
	url = 'http://www.senado.cl/appsenado/index.php?mo=sesionessala&ac=doctosSesion&tipo=27'
	puts '1/3 Descargando la tabla de sesiones de www.senado.cl...'
	file = open(url)
	puts '2/3 Procesando el documento...'
	html = file.read
	robot = TableParserRobot.new(html)
	robot.lamb = lambda {|session, a|
		url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'
		#usar un metodo para pasar a ingles la fecha si es que falla en espanol
		a.push(session)
		data = {
			:date => session["date"],
			:chamber => session["chamber"],
			:legislature => session["legislature"],
			:session => session["session"]
		}
		#RestClient.put url, data, {:content_type => :json}
	}
	result = robot.process
	puts '3/3 Finalizado'
end
