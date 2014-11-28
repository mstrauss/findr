# encoding: utf-8
require 'spec_helper'

def skip_new_ruby
  skip "Incorrect Ruby version." if RUBY_VERSION > '1.9'
end

def skip_old_ruby
  skip "Incorrect Ruby version." if RUBY_VERSION < '1.9'
end


module Findr

  RSpec.describe Encoder do

    let(:utf8_string)   {'123ö'}
    let(:latin1_string) {"123\xF6"}
    let(:cp850_string)  {"123\x94"}

    describe '.list' do
      subject {Encoder.list}

      it 'fails on ruby 1.8' do
        skip_new_ruby
        expect{subject}.to raise_error(Encoder::Error) do |error|
          expect(error.message).to include('Iconv.list not supported')
          expect(error.original).to be_kind_of(NoMethodError)
          expect(error.original.message).to eq("undefined method `list' for Iconv:Class")
        end

      end

      it 'returns a list of supported encodings' do
        skip_old_ruby
        expect(subject).to include('UTF-8')
        expect(subject).to include('ISO-8859-1')
      end
    end

    describe 'decode' do

      it 'should accept single codings' do
        expect(Encoder.new('utf-8').decode(utf8_string)).to eq([utf8_string, 'UTF-8'])
        expect(Encoder.new('iso-8859-1').decode(latin1_string)).to eq([utf8_string, 'ISO-8859-1'])
        expect(Encoder.new('us-ascii').decode('123')).to eq(['123', 'US-ASCII'])
      end

      it 'should accept multiple encodings' do
        expect(Encoder.new('ascii,cp850').decode(cp850_string)).to eq([utf8_string, 'CP850'])
      end

      it 'should fail if no valid coding can be found' do
        expect{Encoder.new('ascii').decode("123\x94")}.to \
          raise_error(Encoder::Error) do |error|
            expect(error.original).to be_kind_of(Encoder::Error)
            expect(error.original.message).to include('No valid coding given')
          end
      end
    end

    describe 'encode' do
      it 'should accept single codings' do
        expect(Encoder.new('utf-8').encode(utf8_string, 'utf-8')).to eq(utf8_string)
      end

    end

  end

end
