# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'

class TableParser
	attr_accessor :html

	def initialize(html)
		@html = html
	end
	def process
		doc = Nokogiri::HTML(@html, nil, 'utf-8')
		doc.xpath('//*[@id="contentTopI"]/div[1]/div[2]/table//tr[(position()>2)]').each do |tr|
			session = get_table(tr)
			@lamb.call(session, @session_buffer)
		end
		@session_buffer
	end
	def get_table(tr)
		url = tr.at_xpath('td[5]/a/@href').to_html.strip
		begin
			file = open(url)
			table_html = file.read
			table_session = get_bills(table_html)
			result = result.merge(table_session)
		rescue Exception=>e
		end	
		result
	end
	def get_bills(table_html = @html)
		bills = table_html.scan(/\(.*Bolet(.*\d*\.{0,1}\d+-\d+)*.*\)/).flatten
		bill_nums = Array.new
		for bill in bills
			for bill_num_array in bill.scan(/(\d{0,3})[^0-9]*(\d{0,3})[^0-9]*(\d{1,3})[^0-9]*(-)[^0-9]*(\d{2})/)
				bill_num = bill_num_array.join
				bill_nums.push(bill_num)
			end
		end
		bill_nums.flatten
	end
end
