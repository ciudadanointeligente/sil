# coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'rest-client'
require 'open-uri'
require 'scrapable_classes'

if !(defined? Test::Unit::TestCase)
	#CurrentHighChamberTable.new.process
	CurrentLowChamberTable.new.process
end
