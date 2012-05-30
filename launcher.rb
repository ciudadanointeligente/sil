# coding: utf-8
require 'rubygems'
require 'rest-client'
require './sil'

url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl?90'
#url = 'test/sil_proyectos5.html'	#Use to local testing
puts '1/3 Descargando el listado de proyectos desde sil.senado.cl...'
file = open(url)
puts '2/3 Descarga terminada'
html = file.read
robot = SilRobot.new(html)
robot.from_where = 1
robot.lamb = lambda {|proyecto, a| puts proyecto["id"]
	url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'
#	url = 'http://localhost:8080/bills'		#Use to local testing
	creation_date = robot.parseaUnaFecha(proyecto["fecha_de_ingreso"])

	data = {
		:stage => proyecto["etapa"],
		:origin_chamber => proyecto["camara_origen"],
		:id => proyecto['id'],
		:title => proyecto["title"],
		:creation_date => proyecto["fecha_de_ingreso"],
		:initiative => proyecto["iniciativa"],
	}

	data.each do |key, value|
		if not value.nil?
			data[key].force_encoding 'Windows-1252'
			data[key].encode! 'utf-8'
		end
	end

	puts '<---------'
	p proyecto
	puts '---------->'
	RestClient.put url, data, {:content_type => :json}
}

resultado = robot.procesar
puts '3/3 Terminado'
