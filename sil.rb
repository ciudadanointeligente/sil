# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'

class SilRobot
	attr_accessor :html, :base_url, :url_tramitacion_base, :lamb, :proyectos_buffer, :url_oficios_base, :url_urgencias_base

	def initialize(html)
		@html = html
		@base_url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl?'
		@url_tramitacion_base = 'http://sil.senado.cl/cgi-bin/'
		@url_oficios_base = 'http://sil.senado.cl/cgi-bin/'
		@url_urgencias_base = 'http://sil.senado.cl/cgi-bin/'
		@lamb = lambda {|proyecto, a| a.push(proyecto) }
		@proyectos_buffer = Array.new
	end
	def procesar
		doc = Nokogiri::HTML(@html, nil, 'utf-8')
		doc.xpath('//html/body/table//tr/td/table//tr/td/table//tr[(position()>1)]').each do |tr|
			proyecto = procesarUnProyectoDeLey(tr)
			@lamb.call(proyecto, @proyectos_buffer)
		end
		@proyectos_buffer
	end
	def procesarUnProyectoDeLey(tr)
		#Definir el nombre de la variable como un tr puesto que es un row en la lista de Proyectos de ley
		result = Hash.new
		result["id"] = tr.at_xpath('td[1]/span/text()').to_s.strip
		#puts 'procesando el proyecto '+ result['id']
		url = tr.at_xpath('td[3]/a/@href').to_html.strip
		begin
			url = @base_url+result["id"]
			file = open(url)
			html = file.read
			resto_del_boletin = procesarUnBoletin(html)
			result = result.merge(resto_del_boletin)
		rescue Exception=>e
		end	
		result
	end
	def procesarUnBoletin(html)
		html = Nokogiri::HTML(html, nil, 'utf-8')
		boletin  = Hash.new
		path_base = "/html/body/table//tr[2]/td[2]/table//"
		path_url = "tr[2]/td/table//tr/td/table//tr/td/table//tr/"
		path_detalle = "tr/td/table//tr/td/table//tr/td/table//tr"
		boletin["title"] = html.at_xpath(path_base+path_detalle+'[2]/td[2]/span/text()').to_s.strip
		boletin["fecha_de_ingreso"] = html.at_xpath(path_base+path_detalle+'[3]/td[2]/span/text()').to_s.strip
		boletin["iniciativa"] = html.at_xpath(path_base+path_detalle+'[4]/td[2]/span/text()').to_s.strip
		boletin["camara_origen"] = html.at_xpath(path_base+path_detalle+'[5]/td[2]/span/text()').to_s.strip
		boletin["etapa"] = html.at_xpath(path_base+path_detalle+'[6]/td[2]/span/text()').to_s.strip
		boletin["url_tramitacion"] = html.at_xpath(path_base+path_url+'td/a/@href').to_s.strip
		boletin["url_oficios"] = html.at_xpath(path_base+path_url+'td[3]/a/@href').to_s.strip
		boletin["url_urgencias"] = html.at_xpath(path_base+path_url+'td[6]/a/@href').to_s.strip
		begin
			url = @url_tramitacion_base+boletin["url_tramitacion"]
			file = open(url)
			html = file.read
			boletin["tramitaciones"] = procesarTramitaciones(html)
		rescue Exception=>e
			# handle e
		end
		begin
			url = @url_oficios_base+boletin["url_oficios"]
			file = open(url)
			html = file.read
			boletin["oficios"] = procesarOficios(html)
		rescue Exception=>e
			# handle e
		end
		begin
			url = @url_urgencias_base+boletin["url_urgencias"]
			file = open(url)
			html = file.read
			boletin["urgencias"] = procesarUrgencias(html)
		rescue Exception=>e
			# handle e
		end
		boletin
	end
	def procesarTramitaciones(html)
		html = Nokogiri::HTML(html, nil, 'utf-8')
		tramitaciones  = Array.new
		html.xpath('/html/body/table//tr/td/table//tr[not(position()<3)]').each do |tr|
			tramitaciones.push(procesarUnaTramitacion(tr))
		end
		tramitaciones
	end
	def procesarUnaTramitacion(tr)
		tramitacion = Hash.new
		tramitacion["sesion"] = tr.at_xpath("td[1]/span/text()").to_s.strip
		tramitacion["fecha"] = tr.at_xpath("td[2]/span/text()").to_s.strip
		tramitacion["subetapa"] = tr.at_xpath("td[3]/span/text()").to_s.strip
		tramitacion["etapa"] = tr.at_xpath("td[4]/span/text()").to_html.strip
		tramitacion
	end
	def procesarOficios(html)
		html = Nokogiri::HTML(html, nil, 'utf-8')
		oficios = Array.new

		html.xpath('/html/body/table//tr/td/table//tr[not(position()<3)]').each do |tr|
			oficios.push(procesaUnOficio(tr))
		end
		oficios
	end
	def procesaUnOficio(tr)
		oficio = Hash.new
		oficio['numero'] = tr.at_xpath("td[1]/span/text()").to_s.strip
		oficio['fecha'] = tr.at_xpath("td[2]/span/text()").to_s.strip
		oficio['oficio'] = tr.at_xpath("td[3]/span/text()").to_s.strip
		oficio['etapa'] = tr.at_xpath("td[4]/span/text()").to_s.strip
		oficio
	end
	def procesarUrgencias(html)
		html = Nokogiri::HTML(html, nil, 'utf-8')
		urgencias = Array.new
		html.xpath('/html/body/table//tr/td/table//tr[not(position()<3)]').each do |tr|
			urgencias.push(procesaUnaUrgencia(tr))
		end
		urgencias
	end
	def procesaUnaUrgencia(tr)
		urgencia = Hash.new
		urgencia['numero'] = tr.at_xpath("td[1]/span/text()").to_s.strip
		urgencia['fecha_inicio'] = tr.at_xpath("td[2]/span/text()").to_s.strip
		urgencia['numero_mensaje_ingreso'] = tr.at_xpath("td[3]/span/text()").to_s.strip
		urgencia['fecha_termino'] = tr.at_xpath("td[4]/span/text()").to_s.strip
		urgencia['numero_mensaje_termino'] = tr.at_xpath("td[5]/span/text()").to_s.strip
		urgencia
	end
	def parseaUnaFecha(fecha)
		fecha.slice! "de "
		english_to_spanish = {
		  'january' => 'Enero',
		  'february' => 'Febrero',
		  'march' => 'Marzo',
		  'april' => 'Abril',
		  'may' => 'Mayo',
		  'june' => 'Junio',
		  'july' => 'Julio',
		  'august' => 'Agosto',
		  'september' => 'Septiembre',
		  'october' => 'Octubre',
		  'november' => 'Noviembre',
		  'december' => 'Diciembre',
		  'monday' => 'Lunes',
		  'tuesday' => 'Martes',
		  'wednesday' => 'Miércoles',
		  'thursday' => 'Jueves',
		  'friday' => 'Viernes',
		  'saturday' => 'Sábado',
		  'sunday' => 'Domingo',
		}
		english_to_spanish.each do |en, es|
			fecha.gsub!(/\b#{es}\b/i, en)
		end
		fecha
	end
end

