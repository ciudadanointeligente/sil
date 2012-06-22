import sys
import re
import urllib
import MLStripper
	
def py_parser(html):
	#get html from url
	file = urllib.urlopen(html)
	html = ""
	for line in file:
		html += line
	#strip html tags
	clean_html = MLStripper.strip_tags(html)
	#get bill numbers
	rx_bills = re.compile('\(.*Bolet(.*\d*\.{0,1}\d+-\d+)*.*\)')
	bills = rx_bills.findall(clean_html)
	#if the table is relevant
	if len(bills) == 0:
		bill_nums = []
		rx_bill_num = re.compile('(\d{0,3})[^0-9]*(\d{0,3})[^0-9]*(\d{1,3})[^0-9]*(-)[^0-9]*(\d{2})')
		for bill in bills:
			for bill_num_array in rx_bill_num.findall(bill):
				bill_num = "".join(bill_num_array)
				bill_nums.append(bill_num)

		#get date
		rx_date = re.compile('(\d{1,2}) (?:de ){0,1}(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre) (?:de ){0,1}(\d{4})')
		date = rx_date.findall(clean_html)
		#date is array of arrays
		date = date[0]
		date = date_sp_2_en(date)
		#get legislature
		rx_legislature = re.compile('LEGISLATURA.+(\d{3})')
		legislature = rx_legislature.findall(clean_html)
		#get session
		rx_session = re.compile('Sesi.+?(\d{1,2})')
		session = rx_session.findall(clean_html)

		#print to stdout
		print "bill numbers: " + ",".join(bill_nums)
		print "date: " + " ".join(date)
		print "legislature: " + legislature[0]
		print "session: " + session[0]
	
	#if the table not contain bills information
	print "is_not_a_relevant_table"

#from d/m/y to m/d/y
#month name from spanish to english
def date_sp_2_en(date):
	day = date [0]
	month = date [1]
	year = date [2]
	
	months = {'enero' : 'january', 'febrero' : 'february', 'marzo' : 'march', 'abril' : 'april', 'mayo' : 'may', 'junio' : 'june', 'julio' : 'july', 'agosto' : 'august', 'septiembre' : 'september', 'octubre' : 'october', 'noviembre' : 'november', 'diciembre' : 'december'}
	
	en_date = [months[month], day, year]
	return en_date

if __name__ == '__main__':
	print sys.argv[1]
	py_parser(sys.argv[1])
