module Findr

  # Wrapper class for String#encode (Ruby >=1.9) and Iconv#iconv (Ruby 1.8).
  class Encoder

    class Error < Findr::Error; end

    include StrategyProxy
    @@strategy = RUBY_VERSION < Findr::FIRST_RUBY_WITHOUT_ICONV ? Encoder::Iconv : Encoder::String

    provides :decode, :string
    provides :encode, :string, :into_coding
    singleton_provides :list

    def initialize( other_codings )
      @strategy = @@strategy.new(other_codings)
    end

  end

end
