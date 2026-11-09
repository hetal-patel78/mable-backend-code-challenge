# frozen_string_literal: true

require 'application/transfer_result'

RSpec.describe TransferResult do
  let(:fields) { %w[1111234522226789 1212343433335665 30.00] }

  it 'lists the six reason codes in order (DEC-19)' do
    expect(described_class::REASON_CODES)
      .to eq(%i[malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds])
  end

  describe 'as a Data record' do
    it 'has the members line_number, fields, reason and header_hint, in that order' do
      expect(described_class.members).to eq(%i[line_number fields reason header_hint])
    end

    it 'is equal to a result built from the same values' do
      expect(described_class.applied(line_number: 1, fields: fields))
        .to eq(described_class.applied(line_number: 1, fields: fields.dup))
    end

    it 'is frozen' do
      expect(described_class.applied(line_number: 1, fields: fields)).to be_frozen
    end

    %i[new []].each do |name|
      it "cannot be built with #{name}, only with applied or rejected" do
        expect { described_class.public_send(name, 1, fields) }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.applied' do
    let(:result) { described_class.applied(line_number: 1, fields: fields) }

    it 'is applied' do
      expect(result.applied?).to be(true)
    end

    it 'is not rejected' do
      expect(result.rejected?).to be(false)
    end

    it 'has no reason' do
      expect(result.reason).to be_nil
    end

    it 'has no header hint' do
      expect(result.header_hint).to be_nil
    end

    it 'returns its line number' do
      expect(result.line_number).to eq(1)
    end

    it 'returns the three fields unchanged, in order' do
      expect(result.fields).to eq(%w[1111234522226789 1212343433335665 30.00])
    end

    it 'keeps the fields frozen' do
      expect(result.fields).to be_frozen
    end
  end

  describe '.rejected' do
    let(:result) { described_class.rejected(line_number: 1, fields: fields, reason: :insufficient_funds) }

    it 'is rejected' do
      expect(result.rejected?).to be(true)
    end

    it 'is not applied' do
      expect(result.applied?).to be(false)
    end

    it 'returns its reason' do
      expect(result.reason).to eq(:insufficient_funds)
    end

    it 'has no header hint unless one is given' do
      expect(result.header_hint).to be_nil
    end

    %i[malformed_row invalid_account_number invalid_amount same_account unknown_account insufficient_funds]
      .each do |reason|
      it "accepts the reason #{reason} (DEC-19)" do
        expect(described_class.rejected(line_number: 1, fields: fields, reason: reason).reason).to eq(reason)
      end
    end

    it 'refuses a reason outside the list' do
      expect { described_class.rejected(line_number: 1, fields: fields, reason: :overdrawn) }
        .to raise_error(ArgumentError)
    end

    it 'refuses a reason outside the list when a result is copied with with' do
      applied = described_class.applied(line_number: 1, fields: fields)
      expect { applied.with(reason: :bogus) }.to raise_error(ArgumentError, 'unknown reason code :bogus')
    end

    it 'keeps a header hint (DEC-06)' do
      hint = 'This looks like a header row; files must not have a header.'
      hinted = described_class.rejected(line_number: 1, fields: %w[from to amount],
                                        reason: :invalid_account_number, header_hint: hint)
      expect(hinted.header_hint).to eq(hint)
    end

    it 'keeps fewer than 3 fields of a malformed row (DEC-19)' do
      short = described_class.rejected(line_number: 4, fields: %w[1111234522226789 1212343433335665],
                                       reason: :malformed_row)
      expect(short.fields).to eq(%w[1111234522226789 1212343433335665])
    end

    it 'keeps more than 3 fields of a malformed row (DEC-19)' do
      long = described_class.rejected(line_number: 2, fields: %w[a b c d], reason: :malformed_row)
      expect(long.fields).to eq(%w[a b c d])
    end

    ['', '10.'].each do |written|
      it "keeps the amount #{written.inspect} as written" do
        kept = described_class.rejected(line_number: 3, fields: ['1111234522226789', '1212343433335665', written],
                                        reason: :invalid_amount)
        expect(kept.fields.last).to eq(written)
      end
    end
  end
end
