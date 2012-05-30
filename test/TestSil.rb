# coding: utf-8
require './sil'
require 'test/unit'
require 'cgi'

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
		expected_title = "Modifica los Códigos de Justicia Militar, Penal y Aeronáutico para abolir la Pena de Muerte."
		expected_fecha = "Tuesday 20 March, 1990"
		expected_iniciativa = "Mensaje"
		expected_camara_origen = "C.Diputados"
		expected_etapa = "Tramitación terminada"
		assert_equal(expected_title, abolir_pena_de_muerte_boletin["title"])
		assert_equal(expected_fecha, abolir_pena_de_muerte_boletin["fecha_de_ingreso"])
		assert_equal(expected_iniciativa, abolir_pena_de_muerte_boletin["iniciativa"])
		assert_equal(expected_camara_origen, abolir_pena_de_muerte_boletin["camara_origen"])
		assert_equal(expected_etapa, abolir_pena_de_muerte_boletin["etapa"])
		assert_equal('./test/sil_tramitacion-1-07.html', abolir_pena_de_muerte_boletin["url_tramitacion"])
		assert_equal('test/sil_oficios-1-07.html', abolir_pena_de_muerte_boletin["url_oficios"])
		assert_equal('test/sil_urgencias-1-07.html', abolir_pena_de_muerte_boletin["url_urgencias"])
		
		assert abolir_pena_de_muerte_boletin.has_key?("oficios"), "no pilló los oficios"
		assert abolir_pena_de_muerte_boletin.has_key?("urgencias"), "no pilló las urgencias"
		assert abolir_pena_de_muerte_boletin.has_key?("tramitaciones"), "no pilló las tramitaciones"
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
		expected_etapa = "Primer trámite constitucional / C.Diputados"
		assert_equal("/", tramitaciones[0]["sesion"])
		assert_equal("11/03/1990", tramitaciones[0]["fecha"])
		assert_equal("Ingreso de proyecto  .", tramitaciones[0]["subetapa"])
		assert_equal(expected_etapa, tramitaciones[0]["etapa"])	
	end
	def test_procesaOficios
		file = File.open("./test/sil_oficios-1-07.html", "rb")
		html = file.read
		oficios = @robot.procesarOficios(html)
		assert_equal 6, oficios.count
	end
	def test_procesaUnOficio
		element = "<tr align=\"center\">
						<td width=\"70\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\">
								<span class=\"TEXTarticulo\">&nbsp;116</span>
						</td>
						<td width=\"80\" bgcolor=\"#FFFFFF\" valign=\"top\" align=\"left\">
							<span class=\"TEXTarticulo\">&nbsp;27/11/90</span>
						</td><td width=\"260\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\">
							<span class=\"TEXTarticulo\">&nbsp;Oficio rechazo modificaciones a Cámara Revisora</span>
						</td>
						<td width=\"130\" bgcolor=\"#FFFFFF\" valign=\"top\" align=\"left\">
							<span class=\"TEXTarticulo\">&nbsp;Tercer trámite constitucional</span>
						</td>
						<td width=\"73\" bgcolor=\"#FFFFFF\" align=\"left\" valign=\"top\">
							<span class=\"TEXTarticulo\">&nbsp;<input type=\"image\" onClick=\"window.open('../../cgi-bin/sil_abredocumentos.pl?3,2410','general','scrollbars=no,width=435,height=300')\" src=\"../../imag/auxi/mas_texto.gif\" border=\"0\" width=\"22\" height=\"15\" alt=\"Obtener documento\"></span>
						</td>
					</tr>"
		tr = Nokogiri::XML(element, nil, 'utf-8')
		oficio = @robot.procesaUnOficio(tr.root)
		assert_equal '116', oficio['numero']
		assert_equal '27/11/90', oficio['fecha']

		oficio_texto = "Oficio rechazo modificaciones a C&#xE1;mara Revisora"
		assert_equal oficio_texto , oficio['oficio']
		assert_equal 'Tercer tr&#xE1;mite constitucional', oficio['etapa']
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
	def test_cambia_codificación

		entrada = Hash.new
		entrada[:a] = "Modifica los C\xF3digos de Justicia Militar, Penal y Aeron\xE1utico para abolir la Pena de Muerte."
		#codificado en utf-8 pero con caractéres raros, que nos hacen la vida complicada
		salida = @robot.codifica(entrada)
		expected_salida = Hash.new
		expected_salida[:a] = "Modifica los Códigos de Justicia Militar, Penal y Aeronáutico para abolir la Pena de Muerte."

		assert_equal salida, expected_salida

	end
	def test_cambia_codificacion_nested_array

		entrada = Hash.new
		entrada[:a] = "C\xF3digoseron\xE1ut"
		entrada[:b] = Hash.new
		entrada[:b][:c] = "\xF3\xE1\xE1"
		#codificado en utf-8 pero con caractéres raros, que nos hacen la vida complicada
		salida = @robot.codifica(entrada)
		expected_salida = Hash.new
		expected_salida[:a] = "Códigoseronáut"
		expected_salida[:b] = Hash.new
		expected_salida[:b][:c] = "óáá"

		assert_equal salida, expected_salida
	end

	def test_codifica_un_array
		tramitacion = Hash.new
		tramitacion["subetapa"] = "\xF3\xE1\xE1"

		expected_tramitacion = Hash.new
		expected_tramitacion["subetapa"] = "óáá"

		salida = @robot.codifica(tramitacion)
		assert_equal salida, expected_tramitacion

	end

end
