# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'
require 'pdf-reader'

class ScrapableSite
	def initialize(url = '')
		@url = url
	end

	def process
		doc_urls.each do |doc_url|
			begin
				doc = read doc_url
				info = get_info doc
				formatted_info = format info
				save formatted_info
			rescue Exception=>e
			end
		end
	end

	def doc_urls
		@url
	end

	def read doc = @url
		open(doc).read
	end

	def get_info doc
		doc
	end

	def format info
		info
	end

	def save info
		p info
	end
		
end

class CongressTable < ScrapableSite

	def initialize()
		super()
		@API_url = 'http://api.ciudadanointeligente.cl/billit/cl/tables'
		@chamber = ''
	end

	def format info
		formatted_info = {
        		:id => info['legislature'] + '-' + info['session'],
                        :date => info['date'],
                        :chamber => @chamber,
                        :legislature => info['legislature'],
                        :session => info['session'],
                        :bill_list => info['bill_list']
		}
	end

	def save formatted_info
		#RestClient.put @API_url, formatted_info, {:content_type => :json}
		p formatted_info
	end

end

class CurrentHighChamberTable < CongressTable
	def initialize()
		super()
		@url = 'http://www.senado.cl/appsenado/index.php?mo=sesionessala&ac=doctosSesion&tipo=27'
		@base_url = 'http://www.senado.cl'
		@chamber = 'Senado'
	end

	#python scripts reads and parses
	def process
                doc_urls.each do |doc_url|
                        begin
                                #doc = read doc_url
                                info = get_info doc_url
                                formatted_info = format info
                                save formatted_info
                        rescue Exception=>e
                        end
                end
        end

	def doc_urls
		html = Nokogiri::HTML(read(@url), nil, 'utf-8')
		doc_urls = Array.new

		html.xpath('//*[@id="contentTopI"]/div[1]/div[2]/table//tr[(position()>2)]').each do |tr|
			table_url = tr.at_xpath('td[5]/a/@href').to_s.strip
                     	doc_urls.push @base_url + table_url
		end
		return doc_urls
	end

	def get_info doc

		info = Hash.new
                #exec python script
                scraped_vals = %x[python table_parser.py '#{doc}'].gsub(/\n/,' ')

                info['session'] = scraped_vals.scan(/session: (\d*)/).flatten[0]
                info['legislature'] = scraped_vals.scan(/legislature: (\d*)/).flatten[0]
                info['date'] = scraped_vals.scan(/date: (\w*) (\d{2}) (\d{4})/).join(' ')
                info['bill_list'] = scraped_vals.scan(/bill numbers: (\S*)/).flatten[0].split(/,/)

		info
        end
end

class CurrentLowChamberTable < CongressTable

	def initialize()
                super()
                @url = 'http://www.camara.cl/trabajamos/sala_sesiones.aspx'
		@base_url = 'http://www.camara.cl/trabajamos/'
                @chamber = 'C.Diputados'
		@session_xpath = '//*[@id="detail"]/table/tbody/tr[1]/td[2]/a'
		@table_xpath = ''
        end

#----- REDEFINED -----
	def doc_urls
		html = Nokogiri::HTML.parse(read(@url), nil, 'utf-8')

		#//*[@id="detail"]/table/tbody/tr[1]/td[2]/a
		#//*[@id="detail"]/table/tbody/tr[2]/td[2]/a

                #doc.xpath('//*[@id="detail"]/table/tbody/tr[(position()>0)]/td[2]/a/@href').each do |tr|
                html.xpath('//*[@id="detail"]/table/tbody/tr[1]/td[2]/a').first['href']
		#p html.css('div.detail a')
	end

	def get_info doc
		reader = PDF::Reader.new("doc")
	end

	#DELETE!!!
	def process
                doc_urls.each do |doc_url|
			p doc_url
                end
        end

#----- NEW -----
	def go_to

	end
end
