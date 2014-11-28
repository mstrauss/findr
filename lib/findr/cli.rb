#!/usr/bin/env ruby
require 'pathname'
require 'tempfile'
require 'optparse'
require 'yaml'
require 'pp'

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
    def gray(text); colorize(text, 2); end
    def bold(text); colorize(text, '1;30'); end
    def bold_yellow(text); colorize(text, '1;33'); end
    def blue_bold(text); colorize(text, '1;34'); end

    def banner
      red( "FINDR VERSION #{Findr::VERSION}. THIS PROGRAM COMES WITH NO WARRANTY WHATSOEVER. MAKE BACKUPS!") + $/ +
      bold( "Usage: #{Pathname($0).basename} [options] <search regex> [<replacement string>]" )
    end

    def show_usage
      puts(@option_parser.help)
      exit
    end

    def execute(stdout, arguments=[])

      @stdout = stdout

      # unless arguments[0]
      # end

      # default options
      options = {}
      options[:coding] = 'utf-8'
      @context_lines = 0

      # parse command line
      @option_parser = OptionParser.new do |opts|
        opts.on('-g', '--glob FILE SEARCH GLOB', 'e.g. "*.{rb,erb}"; glob relative to the current directory') do |glob|
          options[:glob] = glob
          fail "-g option cannot be combined with -G" if options[:gglob]
        end
        opts.on('-G', '--global-glob GLOB', 'e.g. "/**/*.{rb,erb}"; glob may escape the current directory') do |glob|
          options[:gglob] = glob
          fail "-G option cannot be combined with -g" if options[:glob]
        end
        opts.on('-i', '--ignore-case', 'do a case-insensitive search') do
          options[:re_opt_i] = true
        end
        opts.on('-n', '--number-of-context LINES', 'number of lines in context to print') do |lines|
          @context_lines = lines.to_i
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
        opts.on('-v', '--verbose', "verbose output") do
          @verbose = true
        end
      end
      @option_parser.banner = self.banner
      @option_parser.parse!( arguments )

      # default (local) glob
      if !options[:glob] && !options[:gglob]
        options[:glob] = '*'
      end

      # optionally save the configuration to file
      if options[:save]
        options.delete(:save)
        stdout.puts red "Nothing to save." unless options
        File.open( CONFIGFILE, 'w' ) { |file| YAML::dump( options, file ) }
        stdout.puts green "Saved options to file #{CONFIGFILE}."
        exit
      else
        # options from file, if present
        if File.exists?( CONFIGFILE )
          file_options = YAML.load_file(CONFIGFILE)
          file_options.delete(:save)
          options.merge!( file_options )
          stdout.puts green "Using #{CONFIGFILE}."
        end
      end

      # build default global glob from local glob, if necessary
      options[:gglob] = '**/' + options[:glob] unless options[:gglob]

      show_usage if arguments.size == 0
      arguments.clone.each do |arg|
        if !options[:find]
          options[:find] = Regexp.compile( arg, options[:re_opt_i] )
          arguments.delete_at(0)
        elsif !options[:replace]
          options[:replace] = arg
          arguments.delete_at(0)
        else
          show_usage
        end
      end

      show_usage if arguments.size != 0
      stdout.puts green "File inclusion glob: " + options[:gglob]
      stdout.puts green "Searching for regex " + options[:find].to_s

      # some statistics
      stats = {}
      stats[:total_hits] = stats[:local_hits] = stats[:hit_files] = stats[:total_files] = 0

      replacement_done = false
      tempfile = nil

      coder = Encoder.new( options[:coding] )

      verbose "Building file tree..."
      files = Pathname.glob("#{options[:gglob]}")
      verbose ['  ', files.count, ' files found.']
      files.each do |current_file|
        next unless current_file.file?
        verbose ["Reading file ", current_file]
        stats[:total_files] += 1
        stats[:local_hits] = 0
        firstmatch = true
        linenumber = 0
        tempfile = Tempfile.new( 'current_file.basename' ) and verbose(['  Create tempfile ',tempfile.path]) if options[:replace] && options[:force]
        clear_context(); print_post_context = 0
        current_file.each_line do |l|
          begin
            l, coding = coder.decode(l)
          rescue Encoder::Error
            stdout.puts "Skipping file #{current_file} because of error on line #{linenumber}: #{$!.original.class} #{$!.original.message}"
            if tempfile
              tempfile_path = tempfile.path
              tempfile.unlink and verbose(['  Delete tempfile ', tempfile_path])
            end
            break
          end
          linenumber += 1
          if l=~ options[:find]
            stats[:local_hits] += 1
            if firstmatch
              stdout.puts red("#{current_file.cleanpath}:")
            end
            if @context_lines > 0
              pop_context.map do |linenumber, l|
                print_line( linenumber, l, coding, false )
              end
              print_post_context = @context_lines
            end
            print_line( linenumber, l.gsub( /(#{options[:find]})/, bold('\1') ), coding, :bold )
            firstmatch = false
            if options[:replace]
              l_repl = l.gsub( options[:find], options[:replace] )
              tempfile.puts coder.encode(l_repl, coding) if tempfile
              replacement_done = true
              print_line( linenumber, l_repl, coding, :blue )
            end
          else
            if tempfile
              tempfile.puts coder.encode(l, coding)
            end
            if print_post_context > 0
              print_post_context -= 1
              print_line( linenumber, l, coding )
            else
              push_context([linenumber, l])
            end
          end
        end
        if tempfile
          tempfile.close
          if stats[:local_hits] > 0
            FileUtils.cp( tempfile.path, current_file )
            verbose(['  Copy tempfile ', tempfile.path, ' to ', current_file])
          end
          tempfile_path = tempfile.path
          tempfile.unlink and verbose(['  Delete tempfile ', tempfile_path])
        end

        if stats[:local_hits] > 0
          stats[:total_hits] += stats[:local_hits]
          stats[:hit_files] += 1
        end

      end

      # some statistics
      stdout.puts green( "#{stats[:total_hits]} occurences (lines) in #{stats[:hit_files]} of #{stats[:total_files]} files found." )
    end

    def print_line( linenumber, line, coding, color = nil )
      case color
      when :bold
        @stdout.write( bold_yellow( "%6d: " % [linenumber] ) )
        @stdout.write gray("(coding: #{coding}) ")
        @stdout.puts line
      when :blue
        @stdout.write( blue( "%6d: " % [linenumber] ) )
        @stdout.write gray("(coding: #{coding}) ")
        @stdout.puts blue line
      else
        @stdout.write( yellow( "%6d: " % [linenumber] ) )
        @stdout.write gray("(coding: #{coding}) ")
        @stdout.puts line
      end
    end

    def clear_context
      @context = []
    end

    def push_context(line)
      @context.shift if @context.length >= @context_lines
      @context.push(line)
    end

    def pop_context
      return [] unless @context_lines > 0
      c = @context
      clear_context()
      return c
    end

    def verbose(text_or_arry)
      @stdout.puts( gray( Array(text_or_arry).join ) ) if @verbose
    end


  end

end
