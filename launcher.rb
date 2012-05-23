# coding: utf-8
require 'rubygems'
require 'rest-client'
require './sil'

url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl'
puts '1/3 Descargando el listado de proyectos desde sil.senado.cl...'
file = open(url)
puts '2/3 Descarga terminada'
html = file.read
robot = SilRobot.new(html)
robot.lamb = lambda {|proyecto, a| puts proyecto["id"]
	url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'
	
	#preprocesing
	stage = proyecto["etapa"]
	stage.force_encoding 'Windows-1252'
	stage.encode! 'utf-8'
	title = proyecto["title"]
	title.force_encoding 'Windows-1252'
	title.encode! 'utf-8'
	origin_chamber = proyecto["camara_origen"]
	origin_chamber.force_encoding 'Windows-1252'
	origin_chamber.encode! 'utf-8'
	creation_date = proyecto["fecha_de_ingreso"]
	creation_date.force_encoding 'Windows-1252'
	creation_date.encode! 'utf-8'

	data = {
		:stage => stage,
		:origin_chamber => origin_chamber,
		:id => proyecto['id'],
		:title => title,
		:creation_date => creation_date,
	}
#	puts '<---------'
#	p data
#	puts '---------->'
	RestClient.put url, data, {:content_type => :json}
}

resultado = robot.procesar
puts '3/3 Terminado'

