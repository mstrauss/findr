class Findr::Encoder

  class Iconv
    def initialize( other_coding )
      @other_coding = other_coding.split(',')
    end

    # Encodes given +string+ from +@other_coding+ to utf8.
    def decode( string )
      coding = nil
      coded_string = nil
      have_valid_coding = @other_coding.any? do |c|
        begin
          coded_string = ::Iconv.conv('UTF-8', c, string)
          coding = c
          true
        rescue
          false
        end
      end
      fail Error.new("No valid coding given.") unless have_valid_coding
      return [coded_string, coding.to_s.upcase]
    rescue
      raise Error, "Error when decoding from '#{@other_coding}' into 'UTF-8': #{$!}"
      return
    end

    # Encodes given utf8 +string+ into +coding+.
    def encode( string, coding )
      return ::Iconv.conv(coding, 'UTF-8', string)
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
