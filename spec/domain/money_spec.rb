# frozen_string_literal: true

require 'domain/money'
require 'domain/errors'

RSpec.describe Money do
  describe '.amount' do
    {
      '10' => '10.00', '10.5' => '10.50', '10.50' => '10.50', '007.50' => '7.50',
      '550' => '550.00', '5000.00' => '5000.00', '0' => '0.00', '0.00' => '0.00',
      '100' => '100.00', '100.5' => '100.50', '100.50' => '100.50'
    }.each do |text, written|
      it "accepts \"#{text}\" and writes it as #{written} (DEC-09)" do
        expect(described_class.amount(text).to_s).to eq(written)
      end
    end

    %w[1.234 -1.234].each do |text|
      it "rejects \"#{text}\" as having more than 2 decimal places, never rounded (DEC-09)" do
        expect { described_class.amount(text) }
          .to raise_error(InvalidAmount, %(amount "#{text}" has more than 2 decimal places))
      end
    end

    it 'rejects the empty text as empty' do
      expect { described_class.amount('') }.to raise_error(InvalidAmount, 'amount is empty')
    end

    ['abc', '10.', '.50', '+10', '1e3', '$10', '1 0', '1,000.00', '100.', '+100', '$100'].each do |text|
      it "rejects \"#{text}\" as not a valid amount (DEC-09)" do
        expect { described_class.amount(text) }
          .to raise_error(InvalidAmount, %(amount "#{text}" is not a valid amount))
      end
    end
  end

  describe '.balance' do
    it 'names the balance when it has more than 2 decimal places' do
      expect { described_class.balance('1.234') }
        .to raise_error(InvalidAmount, 'balance "1.234" has more than 2 decimal places')
    end

    it 'names the balance when it is not a valid amount' do
      expect { described_class.balance('abc') }.to raise_error(InvalidAmount, 'balance "abc" is not a valid amount')
    end

    it 'names the balance when it is empty' do
      expect { described_class.balance('') }.to raise_error(InvalidAmount, 'balance is empty')
    end
  end

  describe '.new' do
    { 'a Float' => 10.5, 'a String' => '10.50' }.each do |kind, value|
      it "refuses #{kind}, as it needs a BigDecimal" do
        expect { described_class.new(value) }
          .to raise_error(ArgumentError, "Money needs a BigDecimal, got #{value.class}")
      end
    end
  end

  describe '#text' do
    it 'returns the text as written' do
      expect(described_class.amount('007.50').text).to eq('007.50')
    end
  end

  describe '#negative?' do
    %w[0 0.00 10.00].each do |text|
      it "is false for #{text}" do
        expect(described_class.amount(text).negative?).to be(false)
      end
    end

    %w[-5.00 -0 -0.00].each do |text|
      it "is true for #{text}, a written minus sign (DEC-09)" do
        expect(described_class.amount(text).negative?).to be(true)
      end
    end
  end

  describe '#positive?' do
    %w[0.01 10.00].each do |text|
      it "is true for #{text}" do
        expect(described_class.amount(text).positive?).to be(true)
      end
    end

    %w[0 0.00 -0 -0.00 -5.00].each do |text|
      it "is false for #{text}" do
        expect(described_class.amount(text).positive?).to be(false)
      end
    end
  end

  describe '#==' do
    %w[-0 -0.00].each do |text|
      it "treats #{text} as equal to 0 (DEC-09)" do
        expect(described_class.amount(text)).to eq(described_class.amount('0'))
      end
    end

    it 'treats 10.5 as equal to 10.50' do
      expect(described_class.amount('10.5')).to eq(described_class.amount('10.50'))
    end
  end

  describe '#hash' do
    it 'is the same for equal values' do
      expect(described_class.amount('10.5').hash).to eq(described_class.amount('10.50').hash)
    end

    it 'is the same for -0 and 0 (DEC-09)' do
      expect(described_class.amount('-0').hash).to eq(described_class.amount('0').hash)
    end
  end

  describe 'arithmetic' do
    let(:zero) { described_class.amount('0.00') }
    let(:step) { described_class.amount('25.60') }

    def add_times(start, money, times)
      Array.new(times, money).reduce(start, :+)
    end

    def subtract_times(start, money, times)
      Array.new(times, money).reduce(start, :-)
    end

    it 'adds 0.10 and 0.20 to exactly 0.30' do
      expect((described_class.amount('0.10') + described_class.amount('0.20')).to_s).to eq('0.30')
    end

    it 'adds 25.60 one thousand times to exactly 25600.00' do
      expect(add_times(zero, step, 1000).to_s).to eq('25600.00')
    end

    it 'adds 25.60 one thousand times and takes it away one thousand times to exactly 0.00' do
      expect(subtract_times(add_times(zero, step, 1000), step, 1000).to_s).to eq('0.00')
    end

    it 'has no upper limit (DEC-09)' do
      large = described_class.amount('123456789012345678901234567890.12')
      expect((large + described_class.amount('0.01')).to_s).to eq('123456789012345678901234567890.13')
    end

    it 'takes 5.00 from 5.00 to a value that is not negative (DEC-09)' do
      expect((described_class.amount('5.00') - described_class.amount('5.00')).negative?).to be(false)
    end

    it 'writes 5.00 minus 5.00 as 0.00' do
      expect((described_class.amount('5.00') - described_class.amount('5.00')).to_s).to eq('0.00')
    end

    it 'takes 5.01 from 5.00 to a negative value (DEC-09)' do
      expect((described_class.amount('5.00') - described_class.amount('5.01')).negative?).to be(true)
    end

    it 'writes 5.00 minus 5.01 as -0.01' do
      expect((described_class.amount('5.00') - described_class.amount('5.01')).to_s).to eq('-0.01')
    end

    it 'gives a computed value a text equal to its written form' do
      expect((described_class.amount('5.00') + described_class.amount('2.50')).text).to eq('7.50')
    end
  end
end
