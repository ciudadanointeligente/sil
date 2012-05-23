require 'rubygems'
require 'htmlentities'
require 'rest_client'
require  File.join(File.dirname(__FILE__), '.', 'sil')

url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl'
puts '1/3 Descargando el listado de proyectos desde sil.senado.cl...'
file = open(url)
puts '2/3 Descarga terminada'
html = file.read
robot = SilRobot.new(html)
robot.lamb = lambda {|proyecto, a| puts proyecto["id"]
	url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'
	coder = HTMLEntities.new
	
	data = {
		:stage => proyecto["etapa"],
		:origin_chamber => proyecto["camara_origen"],
		:id => proyecto['id'],
		:title => proyecto['title'],
		:creation_date => proyecto["fecha_de_ingreso"],
#		:stage => "API - Example - Etapa",
#		:origin_chamber => "API - Example - Camara Origen",
#		:id => "CL-3456-78",
#		:title => "API - Example - Title",
#		:creation_date => "2009-09-29T04:00:00Z",
	}
	puts '<---------'
	p data
	puts '---------->'
	RestClient.put url, data, {:content_type => :json}
}

resultado = robot.procesar
puts '3/3 Terminado'

