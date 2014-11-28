$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Findr
  FIRST_RUBY_WITHOUT_ICONV = '1.9'
end

require 'iconv' if RUBY_VERSION < Findr::FIRST_RUBY_WITHOUT_ICONV

require 'findr/version'
require 'findr/error'
require 'findr/strategy_proxy'
require 'findr/encoder'
require 'findr/encoder/iconv'
require 'findr/encoder/string'
