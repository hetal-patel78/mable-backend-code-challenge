# frozen_string_literal: true

require 'application/day_result'

RSpec.describe DayResult do
  def applied(line)
    TransferResult.applied(line_number: line, fields: %w[1111234522226789 1212343433335665 10.00])
  end

  def rejected(line, reason)
    TransferResult.rejected(line_number: line, fields: %w[1111234522226789 1212343433335665 10.00], reason: reason)
  end

  def day(*results)
    described_class.new(results: results, total_before: balance('150.00'), total_after: balance('150.00'),
                        accounts: [account], output_path: 'output/day.csv')
  end

  it 'has the warning DEC-21 gives when every transfer is rejected' do
    expect(described_class::ALL_REJECTED_WARNING).to eq('All transfers were rejected; check this is the right file.')
  end

  it 'returns the five members it was given' do
    members = { results: [applied(1)], total_before: balance('150.00'), total_after: balance('149.00'),
                accounts: [account], output_path: 'output/day.csv' }
    expect(described_class.new(**members)).to have_attributes(members)
  end

  context 'with two applied results' do
    subject(:result) { day(applied(1), applied(2)) }

    it 'counts both as processed' do
      expect(result.processed_count).to eq(2)
    end

    it 'counts both as applied' do
      expect(result.applied_count).to eq(2)
    end

    it 'counts none as rejected' do
      expect(result.rejected_count).to eq(0)
    end

    it 'has no counts per reason' do
      expect(result.rejected_counts).to eq({})
    end

    it 'is not all rejected' do
      expect(result.all_rejected?).to be(false)
    end
  end

  context 'with rejected results' do
    it 'lists only the codes that occurred, in DEC-19 order, whatever the file order (DEC-19)' do
      result = day(rejected(1, :insufficient_funds), rejected(2, :same_account), rejected(3, :unknown_account))
      expect(result.rejected_counts.to_a).to eq([[:same_account, 1], [:unknown_account, 1], [:insufficient_funds, 1]])
    end

    it 'counts a header row as processed (DEC-26)' do
      expect(day(rejected(1, :malformed_row)).processed_count).to eq(1)
    end

    it 'counts a header row as rejected (DEC-26)' do
      expect(day(rejected(1, :malformed_row)).rejected_count).to eq(1)
    end

    it 'is all rejected when every result is rejected (DEC-21)' do
      expect(day(rejected(1, :same_account), rejected(2, :invalid_amount)).all_rejected?).to be(true)
    end

    it 'is not all rejected when one result is applied (DEC-21)' do
      expect(day(rejected(1, :same_account), applied(2)).all_rejected?).to be(false)
    end
  end

  it 'is not all rejected with no results (DEC-21)' do
    expect(day.all_rejected?).to be(false)
  end
end
