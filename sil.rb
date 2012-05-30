# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'

class SilRobot
	attr_accessor :html, :base_url, :url_tramitacion_base, :lamb, :proyectos_buffer, :url_oficios_base, :url_urgencias_base, :from_where

	def initialize(html)
		@html = html
		@base_url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl?'
		@url_tramitacion_base = 'http://sil.senado.cl/cgi-bin/'
		@url_oficios_base = 'http://sil.senado.cl/cgi-bin/'
		@url_urgencias_base = 'http://sil.senado.cl/cgi-bin/'
		@lamb = lambda {|proyecto, a| a.push(proyecto) }
		@proyectos_buffer = Array.new
		@from_where = 1
	end
	def procesar
		doc = Nokogiri::HTML(@html)
		doc.xpath('//html/body/table//tr/td/table//tr/td/table//tr[(position()>'+@from_where.to_s+')]').each do |tr|
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
		html = Nokogiri::HTML(html)
		boletin  = Hash.new
		path_base = "/html/body/table//tr[2]/td[2]/table//"
		path_url = "tr[2]/td/table//tr/td/table//tr/td/table//tr/"
		path_detalle = "descendant::*[name() ='tr']/td/table//tr/td/table//tr/td/table//tr"

		boletin["title"] = html.at_xpath(path_base+path_detalle+'[2]/td[2]/span/text()').to_s.force_encoding("utf-8").strip
		boletin["fecha_de_ingreso"] = html.at_xpath(path_base+path_detalle+'[3]/td[2]/span/text()').to_s.force_encoding("utf-8").strip
		boletin["fecha_de_ingreso"] = parseaUnaFecha(boletin["fecha_de_ingreso"])
		boletin["iniciativa"] = html.at_xpath(path_base+path_detalle+'[4]/td[2]/span/text()').to_s.force_encoding("utf-8").strip
		boletin["camara_origen"] = html.at_xpath(path_base+path_detalle+'[5]/td[2]/span/text()').to_s.force_encoding("utf-8").strip
		boletin["etapa"] = html.at_xpath(path_base+path_detalle+'[6]/td[2]/span/text()').to_s.force_encoding("utf-8").strip
		boletin["url_tramitacion"] = html.at_xpath(path_base+path_url+'td/a/@href').to_s.force_encoding("utf-8").strip
		boletin["url_oficios"] = html.at_xpath(path_base+path_url+'td[3]/a/@href').to_s.force_encoding("utf-8").strip
		boletin["url_urgencias"] = html.at_xpath(path_base+path_url+'td[6]/a/@href').to_s.force_encoding("utf-8").strip
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
		codifica(boletin)
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
		tramitacion["sesion"] = tr.at_xpath("td[1]/span/text()").to_s.force_encoding("utf-8").strip
		tramitacion["fecha"] = tr.at_xpath("td[2]/span/text()").to_s.force_encoding("utf-8").strip
		subetapa = tr.at_xpath("td[3]/span/text()").text.force_encoding("utf-8")
		tramitacion["subetapa"] = subetapa.strip
		etapa = tr.at_xpath("td[4]/span/text()").text.force_encoding("utf-8")

		tramitacion["etapa"] = etapa.strip
		codifica(tramitacion)
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
		oficio['numero'] = tr.at_xpath("td[1]/span/text()").to_s.force_encoding("utf-8").strip
		oficio['fecha'] = tr.at_xpath("td[2]/span/text()").to_s.force_encoding("utf-8").strip
		oficio['oficio'] = tr.at_xpath("td[3]/span/text()").to_s.force_encoding("utf-8").strip
		oficio['etapa'] = tr.at_xpath("td[4]/span/text()").to_s.force_encoding("utf-8").strip
		codifica(oficio)
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
		val = tr.at_xpath("td[5]/span/text()").text
		urgencia['numero'] = tr.at_xpath("td[1]/span/text()").to_s.strip
		urgencia['fecha_inicio'] = tr.at_xpath("td[2]/span/text()").to_s.strip
		urgencia['numero_mensaje_ingreso'] = tr.at_xpath("td[3]/span/text()").to_s.strip
		urgencia['fecha_termino'] = tr.at_xpath("td[4]/span/text()").to_s.strip
		urgencia['numero_mensaje_termino'] = tr.at_xpath("td[5]/span/text()").to_s.strip
		codifica(urgencia)
	end
	def parseaUnaFecha(fecha)
		if fecha.nil?
			return
		end
		fecha.slice! "de "
		english_to_spanish = {
		  'January' => 'Enero',
		  'February' => 'Febrero',
		  'March' => 'Marzo',
		  'April' => 'Abril',
		  'May' => 'Mayo',
		  'June' => 'Junio',
		  'July' => 'Julio',
		  'August' => 'Agosto',
		  'September' => 'Septiembre',
		  'October' => 'Octubre',
		  'November' => 'Noviembre',
		  'December' => 'Diciembre',
		  'Monday' => 'Lunes',
		  'Tuesday' => 'Martes',
		  'Wednesday' => 'Miércoles',
		  'Thursday' => 'Jueves',
		  'Friday' => 'Viernes',
		  'Saturday' => 'Sábado',
		  'Sunday' => 'Domingo',
		}
		english_to_spanish.each do |en, es|
			fecha.gsub!(/\b#{es}\b/i, en)
		end
		fecha
	end
	def codifica(diccionario)
		diccionario.each do |key, value|
			if value.class.name == "Hash" || value.class.name == "Array"
				diccionario[key] = codifica(value)
			end
			if value.class.name == "String"
				value.force_encoding 'Windows-1252'
				value.encode! 'utf-8'
				if !value.valid_encoding?
					p '<--- no valid encoding'
					p value
					p 'no valid encoding --->'
				else
					value = value.gsub("Â","")
				end
				diccionario[key] = value

			end
		end
		diccionario
	end
end
	