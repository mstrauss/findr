module Findr

  # Wrapper class for String#encode (Ruby >=1.9) and Iconv#iconv (Ruby 1.8).
  class Encoder

    class Error < Findr::Error; end

    include StrategyProxy

    provides :decode, :string
    provides :encode, :string, :into_coding

    def initialize( other_codings )
      strategy = RUBY_VERSION < Findr::FIRST_RUBY_WITHOUT_ICONV ? Encoder::Iconv : Encoder::String
      @strategy = strategy.new(other_codings)
    end

    class <<self
      if RUBY_VERSION < FIRST_RUBY_WITHOUT_ICONV
        def list
          return ::Iconv.list
        rescue
          fail Error, "Iconv.list not supported on Ruby #{RUBY_VERSION}. Try 'iconv -l' on the command line."
        end
      else
        def list
          return Encoding.list.map(&:to_s)
        end
      end
    end

  end

end
