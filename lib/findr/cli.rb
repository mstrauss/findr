#!/usr/bin/env ruby
require 'pathname'
require 'tempfile'
require 'optparse'
require 'yaml'
require 'pp'

require 'findr/version'
require 'findr/encoder'

module Findr

  class CLI

    CONFIGFILE = '.findr-config'

    def colorize(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end

    def red(text); colorize(text, 31); end
    def green(text); colorize(text, 32); end
    def yellow(text); colorize(text, 33); end
    def blue(text); colorize(text, 34); end

    def banner
      red( "FINDR VERSION #{Findr::VERSION}. THIS PROGRAM COMES WITH NO WARRANTY WHATSOEVER. MAKE BACKUPS!") + $/ +
      "Usage: #{Pathname($0).basename} [options] <search regex> [<replacement string>]"
    end

    def show_usage
      puts(@option_parser.help)
      exit
    end

    def execute(stdout, arguments=[])
      # unless arguments[0]
      # end

      # default options
      options = {}
      options[:glob] = '**/*'
      options[:coding] = 'utf-8'

      # options from file, if present
      if File.exists?( CONFIGFILE )
        file_options = YAML.load_file(CONFIGFILE)
        file_options.delete(:save)
        options.merge!( file_options )
        stdout.puts green "Using #{CONFIGFILE}."
      end

      # parse command line
      @option_parser = OptionParser.new do |opts|
        opts.on('-g', '--glob FILE SEARCH GLOB', 'e.g. "*.{rb,erb}"') do |glob|
          options[:glob] = glob
        end
        opts.on('-x', '--execute', 'actually execute the replacement') do
          options[:force] = true
        end
        opts.on('-c', '--coding FILE CODING SYSTEM', 'e.g. "iso-8859-1"') do |coding|
          options[:coding] = coding
        end
        opts.on('-s', '--save', "saves your options to #{CONFIGFILE} for future use") do
          options[:save] = true
        end
        opts.on('-C', '--codings-list', "list available encodings") do
          pp Encoder.list
          exit
        end
      end
      @option_parser.banner = self.banner
      @option_parser.parse!( arguments )

      # optionally save the configuration to file
      if options[:save]
        options.delete(:save)
        stdout.puts red "Nothing to save." unless options
        File.open( CONFIGFILE, 'w' ) { |file| YAML::dump( options, file ) }
        stdout.puts green "Saved options to file #{CONFIGFILE}."
        exit
      end

      show_usage if arguments.size == 0
      arguments.clone.each do |arg|
        if !options[:find]
          options[:find] = Regexp.compile( arg )
          arguments.delete_at(0)
        elsif !options[:replace]
          options[:replace] = arg
          arguments.delete_at(0)
        else
          show_usage
        end
      end

      show_usage if arguments.size != 0
      stdout.puts green "File inclusion glob: " + options[:glob]
      stdout.puts green "Searching for regex " + options[:find].to_s

      # some statistics
      stats = {}
      stats[:total_hits] = stats[:local_hits] = stats[:hit_files] = stats[:total_files] = 0

      replacement_done = false
      tempfile = nil

      coder = Encoder.new( options[:coding] )

      Pathname.glob("#{options[:glob]}").each do |current_file|
        next unless current_file.file?
        stats[:total_files] += 1
        stats[:local_hits] = 0
        firstmatch = true
        linenumber = 0
        tempfile = Tempfile.new( 'current_file.basename' ) if options[:replace] && options[:force]
        current_file.each_line do |l|
          begin
            l = coder.decode(l)
          rescue Encoder::Error
            stdout.puts "Skipping file #{current_file} because of error on line #{linenumber}: #{$!.original.class} #{$!.original.message}"
            tempfile.unlink if tempfile
            break
          end
          linenumber += 1
          if l=~ options[:find]
            stats[:local_hits] += 1
            if firstmatch
              stdout.puts red("#{current_file.cleanpath}:")
            end
            stdout.write( yellow( "%6d:" % [linenumber, l] ) )
            stdout.puts l
            firstmatch = false
            if options[:replace]
              stdout.write( blue( "%6d:" % [linenumber, l] ) )
              l_repl = l.gsub( options[:find], options[:replace] )
              tempfile.puts coder.encode(l_repl) if tempfile
              stdout.puts blue l_repl
              replacement_done = true
            end
          elsif tempfile
            tempfile.puts coder.encode(l)
          end
        end
        if tempfile
          tempfile.close
          FileUtils.cp( tempfile.path, current_file ) if stats[:local_hits] > 0
          tempfile.unlink
        end

        if stats[:local_hits] > 0
          stats[:total_hits] += stats[:local_hits]
          stats[:hit_files] += 1
        end

      end

      # some statistics
      stdout.puts green( "#{stats[:total_hits]} occurences (lines) in #{stats[:hit_files]} of #{stats[:total_files]} files found." )
    end

  end

end
