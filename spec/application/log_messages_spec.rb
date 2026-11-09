# frozen_string_literal: true

require 'application/log_messages'
require 'application/day_result'
require 'application/transfer_result'

RSpec.describe LogMessages do
  def applied(*fields, line: 1)
    TransferResult.applied(line_number: line, fields: fields)
  end

  def rejected(*fields, reason:, line: 1, header_hint: nil)
    TransferResult.rejected(line_number: line, fields: fields, reason: reason, header_hint: header_hint)
  end

  def day(*results)
    DayResult.new(results: results, total_before: balance('150.00'), total_after: balance('150.00'),
                  opening_balances: {}, accounts: [], output_path: 'output/day.csv')
  end

  describe '.run_started' do
    it 'names both paths as given (DEC-28)' do
      expect(described_class.run_started('balances.csv', 'transfers.csv'))
        .to eq('Run started: balances balances.csv, transfers transfers.csv')
    end
  end

  describe '.applied' do
    it 'gives the line number, the masked accounts and the amount (DEC-28, DEC-29)' do
      expect(described_class.applied(applied('1111234522226789', '1212343433335665', '10.00', line: 2)))
        .to eq('Line 2 applied: ************6789 -> ************5665 10.00')
    end

    it 'gives an amount written 007.50 as 7.50' do
      expect(described_class.applied(applied('1111234522226789', '1212343433335665', '007.50')))
        .to eq('Line 1 applied: ************6789 -> ************5665 7.50')
    end
  end

  describe '.rejected' do
    it 'gives the masked accounts, the amount as written and the reason code (DEC-28, DEC-29)' do
      expect(described_class.rejected(rejected('1111234522226789', '1212343433335665', '100.01',
                                               reason: :insufficient_funds, line: 2)))
        .to eq('Line 2 rejected: ************6789 -> ************5665 100.01 insufficient_funds')
    end

    it 'gives an empty amount as "" (AC-02.2)' do
      expect(described_class.rejected(rejected('', '', '', reason: :invalid_account_number)))
        .to eq('Line 1 rejected: **** -> **** "" invalid_account_number')
    end

    it 'gives the two fields of a row with 2 fields by position (item 8)' do
      two_fields = rejected('1111234522226789', '1212343433335665', reason: :malformed_row, line: 4)
      expect(described_class.rejected(two_fields))
        .to eq('Line 4 rejected: ************6789 -> ************5665 malformed_row')
    end

    it 'gives the one field of a row with 1 field (item 8)' do
      expect(described_class.rejected(rejected('1111234522226789', reason: :malformed_row)))
        .to eq('Line 1 rejected: ************6789 malformed_row')
    end

    it 'gives only the first three fields of a row with 4 fields (item 8)' do
      expect(described_class.rejected(rejected('1111234522226789', '1212343433335665', '1', '000.00',
                                               reason: :malformed_row)))
        .to eq('Line 1 rejected: ************6789 -> ************5665 1 malformed_row')
    end

    it 'never gives the header hint (FR-021)' do
      header = rejected('from', 'to', 'amount', reason: :invalid_account_number, header_hint: 'the header hint')
      expect(described_class.rejected(header)).to eq('Line 1 rejected: **** -> **** amount invalid_account_number')
    end
  end

  describe '.run_ended' do
    it 'gives the counts with no reasons when nothing was rejected (DEC-28)' do
      expect(described_class.run_ended(day(applied('1111234522226789', '1212343433335665', '10.00'))))
        .to eq('Run ended: processed 1, applied 1, rejected 0')
    end

    it "gives the count per reason in brackets, in the order DayResult gives them, separated by ', ' (DEC-28)" do
      results = [rejected('a', 'b', '1', reason: :insufficient_funds), rejected('a', 'a', '1', reason: :same_account),
                 applied('1111234522226789', '1212343433335665', '10.00')]
      expect(described_class.run_ended(day(*results)))
        .to eq('Run ended: processed 3, applied 1, rejected 2 (same_account 1, insufficient_funds 1)')
    end
  end

  describe '.mask' do
    {
      '1111234522226789' => '************6789', '12345' => '*2345', '6789' => '****', 'abc' => '****', '' => '****',
      'from' => '****', '1111-2345-2222-6789' => '***************6789',
      '111123452222678' => '***********2678', '11112345222267890' => '*************7890'
    }.each do |value, masked|
      it "masks #{value.inspect} as #{masked} (DEC-29, AC-09.6)" do
        expect(described_class.mask(value)).to eq(masked)
      end
    end
  end
end
