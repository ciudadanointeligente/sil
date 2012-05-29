# coding: utf-8
require './TableParser'
require 'test/unit'

class TestTableParser < Test::Unit::TestCase
	def setup
		file = File.open("test/tabla_circular_106.html", "rb")
		@html = file.read
		@robot = TableParser.new(@html)
	end
	def test_is_html_doc
		@robot = TableParser.new(@html)
		assert(@robot.html.include?'<html')
	end
	#def test_contains_word_boletin
	#	assert(@robot.html.include?'Bolet')
	#end
	def test_has_boletin_number
		#assert(!@robot.html.scan(/\d*\.{0}\d+-\d+/).empty?)
		assert(!@robot.getBills.empty?)
	end
	def test_bill_amount
		p '-----'
		puts @robot.get_bills
		p '-----'
		assert_equal(@robot.get_bills.count, 16)
	end
end
