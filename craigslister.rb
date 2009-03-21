#!/usr/bin/ruby

# == Synopsis
# craigslister: Downloads listings from Craigslist and puts them in RSS
#
# == Usage
# craigslister [--nopics] [--minprice <min>] [--maxprice <max>]
#              [--query <query>] [--queryfile <file>] [--historyfile <file>]
#
# You must specify either --query <query> or --queryfile <file>.
#
# == Author
# Neil Hooey <nhooey [at] gmail.com>
#
# == Copyright
# Copyright (c) 2009 Neil Hooey. Licensed under the same terms as Ruby.

require 'getoptlong'
require 'open-uri'
require 'rexml/document'
require 'timeout'
require 'net/http'
include REXML

usage = <<EOF
usage: craigslister [--nopics] [--minprice <min>] [--maxprice <max>]
                    < --query <query> | --queryfile <file> >
                    [--historyfile <file>]

You must specify either --query <query> or --queryfile <file>.

EOF

regex_price = /\$(([\d]+,)?[\d]+(\.[\d]+)?)/
months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept',
	'Oct', 'Nov', 'Dec']

def get_cmd_options()
	begin
		getopt = GetoptLong.new(
			['--nopics', '-p', GetoptLong::NO_ARGUMENT],
			['--minprice', '-n', GetoptLong::REQUIRED_ARGUMENT],
			['--maxprice', '-x', GetoptLong::REQUIRED_ARGUMENT],
			['--query', '-q', GetoptLong::REQUIRED_ARGUMENT],
			['--queryfile', '-f', GetoptLong::REQUIRED_ARGUMENT],
			['--historyfile', '-h', GetoptLong::REQUIRED_ARGUMENT],
			['--debug', '-d', GetoptLong::REQUIRED_ARGUMENT]
		)
		opts = {}
		getopt.each do |opt, arg|
			opts[opt[2..-1]] = arg
		end

	rescue GetoptLong::MissingArgument => error
		exit 1
	end

	opts['minprice'] = 'min' unless opts['minprice']
	opts['maxprice'] = 'max' unless opts['maxprice']

	if opts['nopics'] then
		opts['nopics'] = ''
	else
		opts['nopics'] = '&hasPic=1'
	end

	unless opts['query'] or opts['queryfile'] then
		return nil
	end

	return opts
end

def get_html(url)
	begin
		print "Downloading listings...\n"
		return open(URI.escape(url)).read
	rescue OpenURI::HTTPError => error
		$stderr.print "Opening URL: `#{url}' failed: #{error}\n"
		raise
	rescue Timeout::Error => error
		$stderr.print "Opening URL: `#{url}' timed out: #{error}\n"
		raise
	rescue Errno::ECONNRESET => error
		$stderr.print
			"Opening URL: `#{url}' failed, connection reset: #{error}\n"
		raise
	end
end

opts = get_cmd_options()
unless opts
	print usage
	exit 1
end

filename_base_rss = 'base_rss.xml'

page_url = "http://newyork.craigslist.org/search/fuo?query=#{opts['query']}" +
           "&srchType=T&minAsk=#{opts['minprice']}&maxAsk=#{opts['maxprice']}" +
		   "#{opts['nopics']}"

html_doc = ''
if opts['debug'] then
	File.open(opts['debug'], 'r') { |f| html_doc = f.read }
else
	html_doc = get_html(page_url)
end

puts html_doc
