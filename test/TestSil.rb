# coding: utf-8
require './sil'
require 'test/unit'

class TestSil < Test::Unit::TestCase
	def setup
		file = File.open("test/sil_proyectos5.html", "rb")
		@html = file.read
		@robot = SilRobot.new(@html)
		@robot.base_url = 'test/boletin-'
		@robot.url_tramitacion_base = ''
		@robot.url_oficios_base = ''
		@robot.url_urgencias_base = ''
		@robot.from_where = 1
		#@robot.lamb = lambda {|proyecto| puts proyecto }
	end
	def test_htmlExist
		@robot = SilRobot.new(@html)
		assert(@robot.html.start_with?'<html>')
	end
	def test_projectCount
		proyectos = @robot.procesar
		assert_equal(5, proyectos.count)
	end
	def test_primerProyectContainsData
		proyectos = @robot.procesar
		
		assert_equal("1-07", proyectos[0]["id"])
		assert proyectos[0].has_key?("fecha_de_ingreso")
		assert proyectos[0].has_key?("iniciativa")
		assert proyectos[0].has_key?("camara_origen")
		assert proyectos[0].has_key?("etapa")
	end
	def test_segundoProyectContainsData
		proyectos = @robot.procesar

		assert_equal("2-07", proyectos[1]["id"])
	end
	def test_procesaDatosBasicosBoletin
		file = File.open("./test/boletin-1-07", "rb")
		html = file.read
		abolir_pena_de_muerte_boletin = @robot.procesarUnBoletin(html)
		expected_title = "Modifica los Códigos de Justicia Militar, Penal y Aeronáutico para abolir la Pena de Muerte.".encode('ISO-8859-1')
		expected_fecha = "Tuesday 20 March, 1990"
		expected_iniciativa = "Mensaje"
		expected_camara_origen = "C.Diputados"
		expected_etapa = "Tramitación terminada".encode('ISO-8859-1')
		assert_equal(expected_title, abolir_pena_de_muerte_boletin["title"])
		assert_equal(expected_fecha, abolir_pena_de_muerte_boletin["fecha_de_ingreso"])
		assert_equal(expected_iniciativa, abolir_pena_de_muerte_boletin["iniciativa"])
		assert_equal(expected_camara_origen, abolir_pena_de_muerte_boletin["camara_origen"])
		assert_equal(expected_etapa, abolir_pena_de_muerte_boletin["etapa"])
		assert_equal('test/sil_tramitacion-1-07.html', abolir_pena_de_muerte_boletin["url_tramitacion"])
		assert_equal('test/sil_oficios-1-07.html', abolir_pena_de_muerte_boletin["url_oficios"])
		assert_equal('test/sil_urgencias-1-07.html', abolir_pena_de_muerte_boletin["url_urgencias"])
		assert abolir_pena_de_muerte_boletin.has_key?("tramitaciones")
		assert abolir_pena_de_muerte_boletin.has_key?("oficios")
		assert abolir_pena_de_muerte_boletin.has_key?("urgencias")
	end
	def test_procesaTramitaciones
		file = File.open("./test/sil_tramitacion-1-07.html", "rb")
		html = file.read
		tramitaciones = @robot.procesarTramitaciones(html)
		assert_equal(2, tramitaciones.count)
	end
	def test_primerTramite
		file = File.open("./test/sil_tramitacion-1-07.html", "rb")
		html = file.read
		tramitaciones = @robot.procesarTramitaciones(html)
		expected_etapa = " Primer tr\xE1mite constitucional / C.Diputados"
		assert_equal("  /", tramitaciones[0]["sesion"])
		assert_equal(" 11/03/1990", tramitaciones[0]["fecha"])
		assert_equal(" Ingreso de proyecto  .", tramitaciones[0]["subetapa"])
		assert_equal(expected_etapa, tramitaciones[0]["etapa"])	
	end
	def test_procesaOficios
		file = File.open("./test/sil_oficios-1-07.html", "rb")
		html = file.read
		oficios = @robot.procesarOficios(html)
		assert_equal 6, oficios.count
	end
	def test_procesaUnOficio
		element = "<tr align=\"center\"><td width=\"70\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\"><span class=\"TEXTarticulo\">&nbsp;116</span></td><td width=\"80\" bgcolor=\"#FFFFFF\" valign=\"top\" align=\"left\"><span class=\"TEXTarticulo\">&nbsp;27/11/90</span></td><td width=\"260\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\"><span class=\"TEXTarticulo\">&nbsp;Oficio rechazo modificaciones a Cámara Revisora</span></td><td width=\"130\" bgcolor=\"#FFFFFF\" valign=\"top\" align=\"left\"><span class=\"TEXTarticulo\">&nbsp;Tercer trámite constitucional</span></td><td width=\"73\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\"><span class=\"TEXTarticulo\">&nbsp;<input type=\"image\" onClick=\"window.open('../../cgi-bin/sil_abredocumentos.pl?3,2410','general','scrollbars=no,width=435,height=300')\" src=\"../../imag/auxi/mas_texto.gif\" border=\"0\" width=\"22\" height=\"15\" alt=\"Obtener documento\"></span></td></tr>"
		tr = Nokogiri::XML(element)
		oficio = @robot.procesaUnOficio(tr.root)
		assert_equal '116', oficio['numero']
		assert_equal '27/11/90', oficio['fecha']

		oficio_texto = 'Oficio rechazo modificaciones a Cámara Revisora'
		assert_equal oficio_texto , oficio['oficio']
		assert_equal 'Tercer trámite constitucional', oficio['etapa']
	end
	def test_oficiosSonDelTipoOficio
		file = File.open("./test/sil_oficios-1-07.html", "rb")
		html = file.read
		oficios = @robot.procesarOficios(html)
		assert oficios[0].has_key?("numero")
		assert oficios[0].has_key?("fecha")
		assert oficios[0].has_key?("oficio")
		assert oficios[0].has_key?("etapa")
	end
	def test_procesaUrgencias
		file = File.open("./test/sil_urgencias-1-07.html", "rb")
		html = file.read
		urgencias = @robot.procesarUrgencias(html)
		assert_equal 5, urgencias.count
	end
	def test_procesaUnaUrgencia
		tr = Nokogiri::XML('<tr align="center">
           <td width="80" bgcolor="#FFFFFF" align="left" valign="top"><span class="TEXTarticulo">&nbsp;Simple</span></td>
           <td width="80" bgcolor="#FFFFFF" valign="top" align="left"><span class="TEXTarticulo">&nbsp;03/10/90</span></td>
           <td width="80" bgcolor="#FFFFFF" align="left" valign="top"><span class="TEXTarticulo">&nbsp;031090</span></td>
           <td width="80" bgcolor="#FFFFFF" align="left" valign="top"><span class="TEXTarticulo">&nbsp;06/11/90</span></td>
           <td width="80" bgcolor="#FFFFFF" align="left" valign="top"><span class="TEXTarticulo">&nbsp;061190</span></td>
         </tr>', nil, 'utf-8')
		urgencia = @robot.procesaUnaUrgencia(tr.root)
		assert_equal 'Simple' ,urgencia['numero']
		assert_equal '03/10/90' ,urgencia['fecha_inicio']
		assert_equal '031090' ,urgencia['numero_mensaje_ingreso']
		assert_equal '06/11/90' ,urgencia['fecha_termino']
		assert_equal '061190' ,urgencia['numero_mensaje_termino']
	end
	def test_urgenciasSonDelTipoUrgencia
		file = File.open("./test/sil_urgencias-1-07.html", "rb")
		html = file.read
		urgencias = @robot.procesarUrgencias(html)

		assert urgencias[0].has_key? 'numero'
		assert urgencias[0].has_key? 'fecha_inicio'
		assert urgencias[0].has_key? 'numero_mensaje_ingreso'
		assert urgencias[0].has_key? 'fecha_termino'
		assert urgencias[0].has_key? 'numero_mensaje_termino'
	end
	def test_parseaUnaFecha
		require 'date'
		fecha = "Miércoles 1 de Agosto, 1990"
		expected_fecha = "1990-08-01"
		resultado = @robot.parseaUnaFecha fecha
		fecha = Date.parse fecha
		assert_equal expected_fecha, fecha.to_s
	end
	def test_parseaUnaFecha2
		require 'date'
		fecha = "Martes 31 de Julio, 1990"
		expected_fecha = "1990-07-31"
		resultado = @robot.parseaUnaFecha fecha
		fecha = Date.parse fecha
		assert_equal expected_fecha, fecha.to_s
	end
	def test_parseaUnaFechaNula
		fecha = nil
		expected_fecha = nil
		resultado = @robot.parseaUnaFecha fecha
		assert_nil resultado
	end
	def test_procesaProyectoConDiferenteXpath
		file = File.open("./test/boletin-1127-11", "rb")
		html = file.read
		el_diferente = @robot.procesarUnBoletin(html)
		#p el_diferente
	end
end
