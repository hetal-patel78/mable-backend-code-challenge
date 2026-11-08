# frozen_string_literal: true

require 'infrastructure/row'

RSpec.describe Row do
  def row(fields, header_hint: nil)
    described_class.new(line_number: 1, fields: fields, expected_size: 3, header_hint: header_hint)
  end

  describe '#wrong_field_count?' do
    it 'is false for 3 fields when 3 are expected (DEC-19)' do
      expect(row(%w[a b c]).wrong_field_count?).to be(false)
    end

    it 'is true for 2 fields when 3 are expected (DEC-19)' do
      expect(row(%w[a b]).wrong_field_count?).to be(true)
    end

    it 'is true for 4 fields when 3 are expected (DEC-19)' do
      expect(row(%w[a b c d]).wrong_field_count?).to be(true)
    end
  end

  describe '#header_hint' do
    it 'is nil when not given' do
      expect(row(%w[a b c]).header_hint).to be_nil
    end

    it 'returns the text when given (DEC-06)' do
      expect(row(%w[a b c], header_hint: 'hint').header_hint).to eq('hint')
    end
  end

  describe '#==' do
    it 'is equal to a row with the same members' do
      same = described_class.new(line_number: 1, fields: %w[a b c], expected_size: 3)
      expect(row(%w[a b c])).to eq(same)
    end
  end
end
