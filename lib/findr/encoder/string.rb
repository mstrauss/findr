class Findr::Encoder

  class String
    def initialize( other_coding )
      @other_coding = other_coding.split(',').map {|coding| Encoding.find(coding)}
    end

    # Encodes given +string+ from +@other_coding+ to utf8.
    def decode( string )
      coding = nil
      have_valid_coding = @other_coding.any? do |c|
        string.force_encoding(c)
        coding = c
        string.valid_encoding?
      end
      fail Error.new("No valid coding given.") unless have_valid_coding
      return [string.encode('UTF-8'), coding.to_s]
    rescue
      raise Error, "Error when decoding from '#{@other_coding}' into 'UTF-8': #{$!}"
    end

    # Encodes given utf8 +string+ into +coding+.
    def encode( string, coding )
      return string.encode(coding)
    rescue
      raise Error, "Error when encoding from 'UTF-8' into '#{coding}'."
    end

    # Returns a list of valid encodings
    def self.list
      return Encoding.list.map(&:to_s)
    end
  end

end
