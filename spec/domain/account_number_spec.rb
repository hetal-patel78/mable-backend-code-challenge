# frozen_string_literal: true

require 'domain/account_number'
require 'domain/errors'

RSpec.describe AccountNumber do
  describe '.new' do
    it 'keeps a valid number as its text' do
      expect(described_class.new('1111234522226789').to_s).to eq('1111234522226789')
    end

    it 'keeps leading zeros (DEC-08)' do
      expect(described_class.new('0000123412341234').to_s).to eq('0000123412341234')
    end

    %w[1111234522226789 1111234522221234 2222123433331212 1212343433335665 3212343433335755].each do |text|
      it "accepts the sample number #{text} with no check digit (DEC-08)" do
        expect(described_class.new(text).to_s).to eq(text)
      end
    end

    {
      '111123452222678' => '15 digits',
      '11112345222267890' => '17 digits',
      '1111O34522226789' => 'the letter O',
      '1111-2345-2222-6789' => 'dashes',
      '12345' => '5 digits',
      '' => 'no digits'
    }.each do |text, why|
      it "rejects \"#{text}\" (#{why}) as not 16 digits (DEC-08)" do
        expect { described_class.new(text) }
          .to raise_error(InvalidAccountNumber, %(account number "#{text}" must be exactly 16 digits))
      end
    end
  end

  describe 'as a Data record' do
    it 'has the one member text' do
      expect(described_class.members).to eq(%i[text])
    end

    it 'checks a number given by keyword the same way (DEC-08)' do
      expect { described_class.new(text: '12345') }
        .to raise_error(InvalidAccountNumber, 'account number "12345" must be exactly 16 digits')
    end

    it 'is frozen' do
      expect(described_class.new('1111234522226789')).to be_frozen
    end

    it 'keeps its own frozen copy of the text' do
      original = +'1111234522226789'
      number = described_class.new(original)
      original << 'x'
      expect(number.text).to be_frozen.and eq('1111234522226789')
    end
  end

  describe '#==' do
    it 'is equal to a number built from the same text' do
      first = described_class.new('1111234522226789')
      expect(first).to eq(described_class.new('1111234522226789'))
    end

    it 'is not equal to a number built from other text' do
      expect(described_class.new('1111234522226789')).not_to eq(described_class.new('1212343433335665'))
    end
  end

  describe '#hash' do
    it 'finds a Hash value with a second number built from the same text' do
      held = { described_class.new('0000123412341234') => :found }
      expect(held[described_class.new('0000123412341234')]).to eq(:found)
    end
  end
end
