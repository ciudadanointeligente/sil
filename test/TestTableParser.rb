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
		assert(!@robot.get_bills.empty?)
	end
	def test_bill_amount
		assert_equal(16, @robot.get_bills.count)
	end
	def test_bill_number
		assert_equal("7689-07",@robot.get_bills[0])
		assert_equal("5185-03",@robot.get_bills[1])
		assert_equal("7914-11",@robot.get_bills[2])
		assert_equal("7913-04",@robot.get_bills[3])
		assert_equal("7929-04",@robot.get_bills[4])
		assert_equal("5345-04",@robot.get_bills[5])
		assert_equal("7849-11",@robot.get_bills[6])
		assert_equal("5871-12",@robot.get_bills[7])
		assert_equal("7260-06",@robot.get_bills[8])
		assert_equal("5049-01",@robot.get_bills[9])
		assert_equal("7605-01",@robot.get_bills[10])
		assert_equal("6462-24",@robot.get_bills[11])
		assert_equal("8107-04",@robot.get_bills[12])
		assert_equal("8087-04",@robot.get_bills[13])
		assert_equal("8111-04",@robot.get_bills[14])
		assert_equal("8038-04",@robot.get_bills[15])
	end
end
