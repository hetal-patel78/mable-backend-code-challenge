# frozen_string_literal: true

require 'application/load_balances'
require 'domain/account_repository'
require 'infrastructure/csv_rows'

RSpec.describe LoadBalances do
  let(:reader) do
    FakeReader.new([balances_row(1, '1111234522226789', '100.00'),
                    balances_row(2, '1212343433335665', '50.00'),
                    balances_row(3, '0000123412341234', '0.00')])
  end
  let(:repository) { AccountRepository.new }
  let(:loader) { described_class.new(reader, repository) }

  describe '#call' do
    context 'with a valid file' do
      before { loader.call('balances.csv') }

      it 'adds the accounts in file order (DEC-31)' do
        expect(repository.all.map { |held| held.number.to_s })
          .to eq(%w[1111234522226789 1212343433335665 0000123412341234])
      end

      it 'adds the balances in file order (DEC-31)' do
        expect(repository.all.map { |held| held.balance.to_s }).to eq(%w[100.00 50.00 0.00])
      end

      it 'keeps leading zeros, so the account is found by its number as written (DEC-08)' do
        expect(repository.include?(account_number('0000123412341234'))).to be(true)
      end

      it 'accepts a starting balance of 0.00 (DEC-10)' do
        expect(repository.find(account_number('0000123412341234')).balance).to eq(balance('0.00'))
      end

      it 'asks the reader once, with the path it was given' do
        expect(reader.paths).to eq(['balances.csv'])
      end
    end

    it 'returns nil' do
      expect(loader.call('balances.csv')).to be_nil
    end
  end

  describe '#call with problems' do
    def error_for(rows, **failure)
      described_class.new(FakeReader.new(rows, **failure), AccountRepository.new).call('balances.csv')
    rescue InvalidBalancesFile => e
      e
    end

    def problems_for(*rows)
      error_for(rows).problems
    end

    let(:invalid_file_rows) do
      [balances_row(1, '1111234522226789', '5000.00'), balances_row(3, '12345', '100.00'),
       balances_row(4, '1212343433335665', 'abc', '9'), balances_row(5, '1111234522226789', '10.00'),
       balances_row(6, '2222123433331212', '-5.00'), balances_row(7, '3212343433335755', '1.234')]
    end

    it 'lists every problem with its line, in file order (DEC-07, DEC-11, DEC-12)' do
      expect(error_for(invalid_file_rows).message).to eq(
        "the balances file is invalid (5 problems):\n  Line 3: account number \"12345\" must be exactly 16 digits\n  " \
        "Line 4: expected 2 fields, found 3\n  Line 5: account 1111234522226789 appears more than once " \
        "(first on line 1)\n  Line 6: balance \"-5.00\" must not be negative\n  Line 7: balance \"1.234\" has more " \
        'than 2 decimal places'
      )
    end

    it 'counts a single problem in the singular' do
      expect(error_for([balances_row(1, '12345', '50.00')]).message).to eq(
        "the balances file is invalid (1 problem):\n  Line 1: account number \"12345\" must be exactly 16 digits"
      )
    end

    it 'reports each problem of a row in field order, on the same line (DEC-12)' do
      expect(problems_for(balances_row(1, '12345', 'abc'))).to eq(
        ['Line 1: account number "12345" must be exactly 16 digits', 'Line 1: balance "abc" is not a valid amount']
      )
    end

    it 'reports only the field count for a row with 1 field' do
      expect(problems_for(balances_row(1, '1111234522226789'))).to eq(['Line 1: expected 2 fields, found 1'])
    end

    it 'reports only the field count for a row with 3 fields' do
      expect(problems_for(balances_row(1, '1111234522226789', '5000.00', 'x')))
        .to eq(['Line 1: expected 2 fields, found 3'])
    end

    it 'reports an empty balance' do
      expect(problems_for(balances_row(1, '1212343433335665', '50.00'), balances_row(2, '1111234522226789', '')))
        .to eq(['Line 2: balance is empty'])
    end

    it 'reports an empty account number and an empty balance' do
      expect(problems_for(balances_row(1, '1212343433335665', '50.00'), balances_row(2, '', ''))).to eq(
        ['Line 2: account number "" must be exactly 16 digits', 'Line 2: balance is empty']
      )
    end

    it 'reports a duplicate with the same balance, naming the first line (DEC-11, DEC-12)' do
      expect(problems_for(balances_row(1, '1111234522226789', '10.00'), balances_row(2, '1111234522226789', '10.00')))
        .to eq(['Line 2: account 1111234522226789 appears more than once (first on line 1)'])
    end

    it 'reports a duplicate with a different balance, naming the first line (DEC-11, DEC-12)' do
      expect(problems_for(balances_row(1, '1111234522226789', '10.00'), balances_row(2, '1111234522226789', '20.00')))
        .to eq(['Line 2: account 1111234522226789 appears more than once (first on line 1)'])
    end

    it 'reports the duplicate before the balance problem of the same row (DEC-12)' do
      expect(problems_for(balances_row(1, '1111234522226789', '5000.00'), balances_row(2, '1111234522226789', 'abc')))
        .to eq(['Line 2: account 1111234522226789 appears more than once (first on line 1)',
                'Line 2: balance "abc" is not a valid amount'])
    end

    it 'does not see a duplicate of a first copy with an invalid balance (DEC-12, known gap)' do
      expect(error_for([balances_row(1, '1111234522226789', 'abc'), balances_row(2, '1111234522226789', '10.00')])
        .message).to eq("the balances file is invalid (1 problem):\n  Line 1: balance \"abc\" is not a valid amount")
    end

    it 'does not see a duplicate of a first copy with the wrong field count (DEC-12, known gap)' do
      expect(error_for([balances_row(1, '1111234522226789', '5000.00', 'x'),
                        balances_row(2, '1111234522226789', '10.00')]).message)
        .to eq("the balances file is invalid (1 problem):\n  Line 1: expected 2 fields, found 3")
    end

    it 'does not see a duplicate of a first copy with a negative balance (DEC-12, known gap)' do
      expect(error_for([balances_row(1, '1111234522226789', '-5.00'), balances_row(2, '1111234522226789', '10.00')])
        .message).to eq("the balances file is invalid (1 problem):\n  Line 1: balance \"-5.00\" must not be negative")
    end

    it 'names the line the held copy was added from as the first line' do
      expect(problems_for(balances_row(1, '1111234522226789', 'abc'), balances_row(2, '1111234522226789', '10.00'),
                          balances_row(3, '1111234522226789', '20.00')).last)
        .to eq('Line 3: account 1111234522226789 appears more than once (first on line 2)')
    end

    it 'adds the header hint after the account number problem (DEC-06)' do
      expect(problems_for(balances_row(1, 'account', 'balance', header_hint: CsvRows::HEADER_HINT))).to eq(
        ['Line 1: account number "account" must be exactly 16 digits. This looks like a header row; files must not ' \
         'have a header.', 'Line 1: balance "balance" is not a valid amount']
      )
    end

    it 'adds the header hint after the field count problem (DEC-06)' do
      expect(problems_for(balances_row(1, 'account', 'balance', 'x', header_hint: CsvRows::HEADER_HINT))).to eq(
        ['Line 1: expected 2 fields, found 3. This looks like a header row; files must not have a header.']
      )
    end

    it 'adds no hint to a row the reader did not mark (DEC-06)' do
      expect(problems_for(balances_row(1, '1111O34522226789', '100.00')))
        .to eq(['Line 1: account number "1111O34522226789" must be exactly 16 digits'])
    end

    it 'reports both an invalid account number and a negative balance' do
      expect(problems_for(balances_row(1, '12345', '-5.00'))).to eq(
        ['Line 1: account number "12345" must be exactly 16 digits', 'Line 1: balance "-5.00" must not be negative']
      )
    end

    it 'stops with the no-rows message when the file has no rows (DEC-11)' do
      expect(error_for([]).message).to eq('the balances file has no rows: balances.csv')
    end

    it 'adds a line that cannot be read as the last problem (DEC-04, DEC-12)' do
      rows = [balances_row(1, '1111234522226789', '100.00'), balances_row(3, '12345', '100.00')]
      expect(error_for(rows, unreadable_at: 7).message).to eq(
        "the balances file is invalid (2 problems):\n  Line 3: account number \"12345\" must be exactly 16 digits\n  " \
        'Line 7: cannot read balances.csv from this line. Check for an unclosed quote or characters that are not text.'
      )
    end

    it 'reports an unreadable line 1 as a problem, not as no rows (DEC-04, DEC-11)' do
      expect(error_for([], unreadable_at: 1).message).to eq(
        "the balances file is invalid (1 problem):\n  Line 1: cannot read balances.csv from this line. " \
        'Check for an unclosed quote or characters that are not text.'
      )
    end

    it 'lets a file that cannot be opened pass through unchanged' do
      unopened = UnreadableFile.cannot_open('balances.csv', Errno::EACCES.new)
      unopenable = described_class.new(FakeReader.new([], error: unopened), repository)
      expect { unopenable.call('balances.csv') }.to raise_error(be(unopened))
    end

    it 'gives the count of problems as the stop reason' do
      expect(error_for(invalid_file_rows).stop_reason).to eq('balances file invalid: 5 problems')
    end

    it 'gives one problem as the stop reason when the file has no rows' do
      expect(error_for([]).stop_reason).to eq('balances file invalid: 1 problem')
    end
  end
end
