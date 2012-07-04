# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'

class SilRobot
	attr_accessor :html, :base_url, :url_tramitacion_base, :lamb, :proyectos_buffer, :url_oficios_base, :url_urgencias_base, :from_where, :url_autores_base

	def initialize(html)
		@html = html
		@base_url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl?'
		@url_tramitacion_base = 'http://sil.senado.cl/cgi-bin/'
		@url_oficios_base = 'http://sil.senado.cl/cgi-bin/'
		@url_urgencias_base = 'http://sil.senado.cl/cgi-bin/'
		@url_autores_base = 'http://sil.senado.cl/cgi-bin/'
		@lamb = lambda {|proyecto, a| 
			a.push(proyecto)
		}
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

		boletin["title"] = html.at_xpath(path_base+path_detalle+'[2]/td[2]/span/text()').text.strip
		boletin["fecha_de_ingreso"] = html.at_xpath(path_base+path_detalle+'[3]/td[2]/span/text()').text.strip
		boletin["fecha_de_ingreso"] = parseaUnaFecha(boletin["fecha_de_ingreso"])
		boletin["iniciativa"] = html.at_xpath(path_base+path_detalle+'[4]/td[2]/span/text()').text.strip
		boletin["camara_origen"] = html.at_xpath(path_base+path_detalle+'[5]/td[2]/span/text()').text.strip
		boletin["etapa"] = html.at_xpath(path_base+path_detalle+'[6]/td[2]/span/text()').text.strip
		if !html.at_xpath(path_base+path_detalle+'[5]/td[4]/span/text()').nil?
			boletin["urgencia_actual"] = html.at_xpath(path_base+path_detalle+'[5]/td[4]/span/text()').text.strip
		else
			boletin["urgencia_actual"] = ""
		end
		boletin["url_tramitacion"] = html.at_xpath(path_base+path_url+'td/a/@href').text.strip

		boletin["url_oficios"] = html.at_xpath(path_base+path_url+'td[3]/a/@href').text.strip
		boletin["url_urgencias"] = html.at_xpath(path_base+path_url+'td[6]/a/@href').text.strip
		url_autores = html.at_xpath('//td[7]/a/@href')
		if !url_autores.nil?
			boletin["url_autores"] = url_autores.text.strip
			begin
				url = @url_autores_base+boletin["url_autores"]
				file = open(url)
				html = file.read
				boletin["autores"] = procesaAutores(html)
			rescue Exception=>e
				# handle e
			end
		end
		
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
		tramitacion["sesion"] = tr.at_xpath("td[1]/span/text()").text.strip
		tramitacion["fecha"] = tr.at_xpath("td[2]/span/text()").text.strip
		subetapa = tr.at_xpath("td[3]/span/text()").text
		tramitacion["subetapa"] = subetapa.strip
		etapa = tr.at_xpath("td[4]/span/text()").text

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
		oficio['numero'] = tr.at_xpath("td[1]/span/text()").text.strip
		oficio['fecha'] = tr.at_xpath("td[2]/span/text()").text.strip
		oficio['oficio'] = tr.at_xpath("td[3]/span/text()").text.strip
		oficio['etapa'] = tr.at_xpath("td[4]/span/text()").text.strip
		
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
		val = tr.at_xpath("td[5]/span/text()").to_s
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
					value = value.gsub('Â', '')
					value = value.gsub(/\\xA0|\\xC2/, '')
					value.strip!
				end
				diccionario[key] = value

			end
		end
		diccionario
	end
	def procesaAutores(html)
		html = Nokogiri::HTML(html, nil, 'utf-8')
		autores = Array.new
		html.xpath('//tr[contains(@align, \'center\') and (position()>2)]').each do |tr|
			autores.push(procesaUnAutor(tr))
		end
		autores
	end
	def procesaUnAutor(tr)
		autor = Hash.new
		autor['nombre'] = tr.at_xpath("td/span[contains(@class,'TEXTarticulo')]/text()").to_s
		codifica(autor)

	end
end
	


if !(defined? Test::Unit::TestCase)
	url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl?'
	puts '1/3 Descargando el listado de proyectos desde sil.senado.cl...'
	file = open(url)
	puts '2/3 Descarga terminada'
	html = file.read
	robot = SilRobot.new(html)
	robot.from_where = 1
	robot.lamb = lambda {|proyecto, a|
		url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'
		creation_date = robot.parseaUnaFecha(proyecto["fecha_de_ingreso"])
		a.push(proyecto)
		nombres_en_plano = Array.new
		if !proyecto['autores'].nil?
			proyecto['autores'].each do |author|
				nombres_en_plano.push(author['nombre'].strip)
			end
		end
		events = Hash.new
		events_counter = 0
		proyecto["tramitaciones"].each do |tramitacion|
			the_event = {
				"session" => tramitacion["sesion"],
				"start_date" => tramitacion["fecha"],
				"end_date" => tramitacion["fecha"],
				"stage" => tramitacion["etapa"],
				"sub_stage" => tramitacion["subetapa"],
				"type" => "Tramitación"
			}
			events[events_counter.to_s.to_sym] = the_event
			events_counter += 1
		end

		proyecto["urgencias"].each do |urgencia|
			the_event = {
				"number" => urgencia['numero'],
				"start_date" => urgencia['fecha_inicio'],
				"end_date" => urgencia['fecha_termino'],
				"number_message_start" => urgencia['numero_mensaje_ingreso'],
				"number_message_start" => urgencia['numero_mensaje_termino'],
				"type" => "Urgencia"
			}
			events[events_counter.to_s.to_sym] = the_event
			events_counter += 1
		end

		data = {
			:stage => proyecto["etapa"],
			:origin_chamber => proyecto["camara_origen"],
			:id => proyecto['id'],
			:title => proyecto["title"],
			:creation_date => proyecto["fecha_de_ingreso"],
			:initiative => proyecto["iniciativa"],
			:authors => nombres_en_plano,
			:current_urgency => proyecto["urgencia_actual"],
			:events => events

		}
		p '<<<<<-----proyecto id :'+ proyecto["id"]
		p data
		p '----->>>>>'
		
		RestClient.put url, data, {:content_type => :json}





	}

	resultado = robot.procesar
	puts '3/3 Terminado'



end

