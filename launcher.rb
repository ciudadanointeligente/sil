require 'json'
require  File.join(File.dirname(__FILE__), '.', 'sil')

url = 'http://sil.senado.cl/cgi-bin/sil_proyectos.pl'
file = open(url)
html = file.read
robot = SilRobot.new(html)
robot.proyectos_buffer = File.new('out.json', 'w')
robot.lamb = lambda {|proyecto, a| a.write(JSON.generate(proyecto))}
resultado = robot.procesar

