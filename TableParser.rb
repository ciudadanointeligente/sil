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
			session = process_a_session(tr)
			@lamb.call(session, @session_buffer)
		end
		@session_buffer
	end
	def process_a_session(tr)
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
		bills = table_html.scan(/\(Bolet.*\)/)
		bill_num = []
		for bill in bills
			bill_num.push(bill.scan(/\d*\.{0}\d+-\d+/))
		end
		bill_num
	end
end
