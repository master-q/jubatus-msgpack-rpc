#!/usr/bin/env ruby

require 'optparse'

conf = {
	:outdir  => nil,
	:lang    => nil,
	:verbose => false,
}

op = OptionParser.new
op.on('-o', '--output DIR') {|s| conf[:outdir] = s }
op.on('-g', '--gen LANG')   {|s| conf[:lang] = s }
op.on('-v', '--verbose')    { conf[:verbose] = true }
op.banner += " <input>"

(class<<self;self;end).module_eval {
	define_method(:usage) {|msg|
		puts op.to_s
		puts msg if msg
		exit 1
	}
}

op.parse!(ARGV)

begin
	op.parse!(ARGV)
	usage(nil) if ARGV.length != 1

	input = ARGV.shift

	lang = conf[:lang]
	usage("-g option is required") unless lang

	outdir = conf[:outdir]
	outdir ||= "gen-#{lang}"

	verbose = conf[:verbose]

rescue
	usage($!.to_s)
end

require 'rubygems'
require 'treetop'
require 'mprpc_idl'
require 'mprpc_ast'
require 'mprpc_ast_impl'
require 'mplex'

begin
	require "lang/#{lang}"
rescue LoadError
	usage("'#{lang}' is not supported.")
end

require 'lang/lang'  # LANGDIR

if input == "-"
	in_fname = "(stdin)"
	in_body  = STDIN.read
else
	in_fname = input
	in_body  = File.read(in_fname)
end

parser = MessagePackIDLParser.new
sn = parser.parse(in_body)

doc = sn.ast
doc.normalize!(conf)

if verbose
	require 'pp'
	pp doc
end

Dir.mkdir(outdir) unless File.directory?(outdir)
outdir = File.expand_path(outdir)
langdir = File.expand_path(LANGDIR)

generate(doc, outdir, langdir)
