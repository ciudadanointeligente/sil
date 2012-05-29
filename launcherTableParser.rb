# coding: utf-8
require 'rubygems'
require 'rest-client'
require './TableParser'

#url = 'http://www.senado.cl/appsenado/index.php?mo=sesionessala&ac=doctosSesion&tipo=27'
url = 'test/tabla_sesionessala.html'	#Use to local testing
puts '1/3 Descargando la Tabla de sesiones de www.senado.cl...'
file = open(url)
puts '2/3 Descarga terminada'
html = file.read
robot = TableParser.new(html)
robot.lamb = lambda {|session, a| puts session["id"]
	url = 'http://api.ciudadanointeligente.cl/billit/cl/bills'

	data = {
		:legislatura => session["legislatura"],
		:nro_sesion => session["nro_sesion"],
	}

	puts '<---------'
	p data
	puts '---------->'
	#RestClient.put url, data, {:content_type => :json}
}

resultado = robot.process
puts '3/3 Terminado'
