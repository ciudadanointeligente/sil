# coding: utf-8
#require 'rubygems'
#require 'nokogiri'
#require 'open-uri'

class TableParser
	attr_accessor :html, :chamber, :bill_nums, :date, :legislature, :session

	def initialize(html, chamber)
		@html = html
		@chamber = chamber
    @bill_nums
    @date
    @legislature
    @session
	end
	def get_table(table_html = @html)
	  table_info = `python table_parser.py #{table_html}`
    values = table_info.split(';')
    #remove prefix with name of value
    @bill_nums = values[0].split(': ')[1]
    @date = values[1].split(': ')[1]
    @legislature = values[2].split(': ')[1]
    @session = values[3].split(': ')[1]
	end
#	
#	def process
#		doc = Nokogiri::HTML(@html, nil, 'utf-8')
#		doc.xpath('//*[@id="contentTopI"]/div[1]/div[2]/table//tr[(position()>2)]').each do |tr|
#			session = get_table(tr)
#			@lamb.call(session, @session_buffer)
#		end
#		@session_buffer
#	end
#	def get_table(tr)
#		url = tr.at_xpath('td[5]/a/@href').to_html.strip
#		begin
#			file = open(url)
#			table_html = file.read
#			table_session = get_bills(table_html)
#			result = result.merge(table_session)
#		rescue Exception=>e
#		end	
#		result
#	end
#	def get_bills(table_html = @html)
#		bills = table_html.scan(/\(.*Bolet(.*\d*\.{0,1}\d+-\d+)*.*\)/).flatten
#		bill_nums = Array.new
#		for bill in bills
#			for bill_num_array in bill.scan(/(\d{0,3})[^0-9]*(\d{0,3})[^0-9]*(\d{1,3})[^0-9]*(-)[^0-9]*(\d{2})/)
#				bill_num = bill_num_array.join
#				bill_nums.push(bill_num)
#			end
#		end
#		bill_nums.flatten
#	end
end
