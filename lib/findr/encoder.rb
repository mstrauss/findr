FIRST_RUBY_WITHOUT_ICONV = '1.9'
require 'iconv' if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV

module Findr

  # Class for wrapping original exceptions, which could be from Iconv (Ruby 1.8)
  # or String (Ruby >=1.9).
  # ()
  class Error < ::StandardError
    attr_reader :original
    def initialize(msg, original=$!)
      super(msg)
      @original = original;
    end
  end

  # Wrapper class for String#encode (Ruby >=1.9) and Iconv#iconv (Ruby 1.8).
  class Encoder

    class Error < Findr::Error; end

    class <<self
      def list
        return Iconv.list if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV
        return Encoding.list.map(&:to_s)
      end
    end

    def initialize( other_coding )
      if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV
        @coding_to_utf8 = Iconv.new('UTF-8', other_coding)
        @utf8_to_coding = Iconv.new(other_coding, 'UTF-8')
      else
        @other_coding = other_coding.split(',').map {|coding| Encoding.find(coding)}
      end
    end

    # Encodes given +string+ from +@other_coding+ to utf8.
    def decode( string )
      return @coding_to_utf8.iconv(string) if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV
      coding = nil
      have_valid_coding = @other_coding.any? do |c|
        string.force_encoding(c)
        coding = c
        string.valid_encoding?
      end
      fail Error.new("No valid coding given.") unless have_valid_coding
      return [string.encode('UTF-8'), coding]
    rescue
      raise Error, "Error when decoding from '#{@other_coding}' into 'UTF-8'."
    end

    # Encodes given utf8 +string+ into +@other_coding+.
    def encode( string, coding )
      return @utf8_to_coding.iconv(string) if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV
      return string.encode(coding)
    rescue
      raise Error, "Error when encoding from 'UTF-8' into '#{coding}'."
    end
  end

end
