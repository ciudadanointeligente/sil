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

	def read url = @url
		# it would be better if instead we used
		# mimetype = `file -Ib #{path}`.gsub(/\n/,"")
		if !url.scan(/pdf/).empty?
			doc_pdf = PDF::Reader.new(open(url))
			doc = ''
			doc_pdf.pages.each do |page|
				doc += page.text
			end
		else
			doc = open(url).read
		end
		doc
	end

	def get_link(url, base_url, xpath)
                html = Nokogiri::HTML.parse(read(url), nil, 'utf-8')
                base_url + html.xpath(xpath).first['href']
        end

#----- Undefined Functions -----

	def doc_urls
		[@url]
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
        		:uid => info['legislature'] + '-' + info['session'],
                        :date => info['date'],
                        :chamber => @chamber,
                        :legislature => info['legislature'],
                        :session => info['session'],
                        :bill_list => info['bill_list']
		}
	end

	def save formatted_info
		RestClient.put @API_url, formatted_info, {:content_type => :json}
		#p formatted_info
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
                info['bill_list'] = scraped_vals.scan(/bill numbers: (\S*);/).flatten[0].split(/,/)

		info
        end
end

class CurrentLowChamberTable < CongressTable

	def initialize()
                super()
                @url = 'http://www.camara.cl/trabajamos/sala_sesiones.aspx'
                @chamber = 'C.Diputados'
		@session_base_url = 'http://www.camara.cl/trabajamos/'
		@table_base_url = 'http://www.camara.cl'
		@session_xpath = '//*[@id="detail"]/table/tbody/tr[1]/td[2]/a'
		@table_xpath = '//*[@id="ctl00_mainPlaceHolder_docpdf"]/li/a'
        end

#----- REDEFINED -----
	def doc_urls
		doc_urls_array = Array.new
		session_url = get_link(@url, @session_base_url, @session_xpath)
		table_url = get_link(session_url, @table_base_url, @table_xpath)
		doc_urls_array.push(table_url)
                # get all with doc.xpath('//*[@id="detail"]/table/tbody/tr[(position()>0)]/td[2]/a/@href').each do |tr|
	end

	def get_info doc
		# get bills
		rx_bills = /Bolet(.*\d+-\d+)*/
		bills = doc.scan(rx_bills)
		
		bill_list = []
		rx_bill_num = /(\d{0,3})[^0-9]*(\d{0,3})[^0-9]*(\d{1,3})[^0-9]*(-)[^0-9]*(\d{2})/
		bills.each do |bill|
			bill.first.scan(rx_bill_num).each do |bill_num_array|
				bill_num = (bill_num_array).join('')
				bill_list.push(bill_num)
			end
		end

		#get date
		rx_date = /(\d{1,2}) (?:de ){0,1}(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre) (?:de ){0,1}(\d{4})/
		date_sp = doc.scan(rx_date).first
		date = date_sp_2_en(date_sp).join(' ')

		# get legislature
		rx_legislature = /(\d{3}).+LEGISLATURA/
		legislature = doc.scan(rx_legislature).flatten.first

		# get session
		rx_session = /Sesi.+?(\d{1,3})/
		session = doc.scan(rx_session).flatten.first

		return {'bill_list' => bill_list, 'date' => date, 'legislature' => legislature, 'session' => session}
	end

	def date_sp_2_en date
		day = date [0]
		month = date [1]
		year = date [2]
	
		months = {'enero' => 'january', 'febrero' => 'february', 'marzo' => 'march', 'abril' => 'april', 'mayo' => 'may', 'junio' => 'june', 'julio' => 'july', 'agosto' => 'august', 'septiembre' => 'september', 'octubre' => 'october', 'noviembre' => 'november', 'diciembre' => 'december'}
	
		en_date = [months[month], day, year]
		return en_date
	end

end
