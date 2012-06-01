#!/usr/bin/env ruby -w
require 'pathname'
require 'tempfile'

# this is deprecated on 1.9, but still works fine
require 'iconv'

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def blue(text); colorize(text, 34); end

unless ARGV[0]
  puts red "Usage: #{$0} <search regex> [<replacement string>] [-b <search basename>] [-e <comma sep. extension list>] [-f]"
  exit 0
end

# search parameters
basename = "*"
extensions = "txt"

haveFind = haveReplace = nextIsBasename = nextIsExtension = inPlaceReplace = false
find = replace = nil

ARGV.each do |arg|
  if /^-f$/ =~ arg
    inPlaceReplace = true
  elsif /^-b$/ =~ arg
    nextIsBasename = true
  elsif /^-b(.*)/ =~ arg
    basename = $1.strip
  elsif nextIsBasename
    basename = arg.strip
    nextIsBasename = false
  elsif /^-e$/ =~ arg
    nextIsExtension = true
  elsif /^-e(.*)/ =~ arg
    extensions = $1.strip
  elsif nextIsExtension
    extensions = arg.strip
    nextIsExtension = false
  elsif !haveFind
    find = Regexp.compile( ARGV[0] )
    haveFind = true
  elsif !haveReplace
    replace = arg
    haveReplace = true
  else
    throw "Uaagh. Invalid command line."
  end
end

puts green "Extensions: " + extensions


puts green "Seraching for regex " + find.to_s

total_hits = local_hits = total_files = 0

replacement_done = false
tempfile = nil

latin_to_utf8 = Iconv.new("utf-8", "iso-8859-1")
utf8_to_latin1 = Iconv.new("iso-8859-1", "utf-8")

Pathname.glob("**/#{basename}.{#{extensions}}").each do |x|
  total_files += 1
  local_hits = 0
  firstmatch = true
  linenumber = 0
  tempfile = Tempfile.new( x.basename ) if replace && inPlaceReplace
  x.each_line do |l|
    l = latin_to_utf8.iconv(l)
    linenumber += 1
    if l=~ find
      total_hits += 1
      local_hits += 1
      if firstmatch
        puts red("#{x.cleanpath}:") 
      end
      $stdout.write( yellow( "%6d:" % [linenumber, l] ) )
      puts l
      firstmatch = false
      if replace
        $stdout.write( blue( "%6d:" % [linenumber, l] ) )
        l_repl = l.gsub( find, replace )
        tempfile.puts utf8_to_latin1.iconv(l_repl) if tempfile
        puts blue l_repl
        replacement_done = true
      end
    elsif tempfile
      tempfile.puts utf8_to_latin1.iconv(l)
    end
  end
  if tempfile
    tempfile.close
    FileUtils.cp( tempfile.path, x ) if local_hits > 0
    tempfile.unlink
  end
end

# some statistics
puts green( "#{total_hits} occurences (lines) in #{total_files} files found." )
