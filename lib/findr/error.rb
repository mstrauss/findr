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

end
