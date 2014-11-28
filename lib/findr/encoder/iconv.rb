class Findr::Encoder

  class Iconv
    def initialize( other_coding )
      @coding_to_utf8 = ::Iconv.new('UTF-8', other_coding)
      @utf8_to_coding = ::Iconv.new(other_coding, 'UTF-8')
    end

    # Encodes given +string+ from +@other_coding+ to utf8.
    def decode( string )
      return @coding_to_utf8.iconv(string)
    end

    # Encodes given utf8 +string+ into +coding+.
    def encode( string, coding )
      return @utf8_to_coding.iconv(string)
    rescue
      raise Error, "Error when encoding from 'UTF-8' into '#{coding}'."
    end

    # Returns a list of valid encodings
    def self.list
      return ::Iconv.list
    rescue
      fail Error, "Iconv.list not supported on Ruby #{RUBY_VERSION}. Try 'iconv -l' on the command line."
    end
  end

end
