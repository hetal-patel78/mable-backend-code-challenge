# frozen_string_literal: true

require 'application/process_daily_transfer'
require 'domain/account_repository'
require 'infrastructure/csv_rows'
require 'infrastructure/errors'
require 'infrastructure/final_balances_csv_writer'
require 'infrastructure/row'

RSpec.describe ProcessDailyTransfer do
  subject(:result) { day.call('balances.csv', 'transfers.csv', 'output/day.csv') }

  around { |example| in_temp_folder { example.run } }

  let(:balances_reader) do
    FakeReader.new([balances_row(1, '1111234522226789', '100.00'), balances_row(2, '1212343433335665', '50.00'),
                    balances_row(3, '0000123412341234', '0.00')])
  end
  let(:transfers_reader) do
    FakeReader.new([transfers_row(1, '1111234522226789', '1212343433335665', '10.00'),
                    transfers_row(2, '1212343433335665', '1111234522226789', '5.00')])
  end
  let(:reporter) { FakeReporter.new }
  let(:logger) { memory_logger }

  def parts
    { balances_reader: balances_reader, transfers_reader: transfers_reader, writer: FinalBalancesCsvWriter.new,
      repository: AccountRepository.new, reporter: reporter, logger: logger }
  end

  def day(**changed)
    described_class.new(run_time: Time.new(2026, 11, 7, 14, 30, 5), **parts, **changed)
  end

  describe '#call with applied rows only' do
    it 'returns the applied results in file order' do
      expect(result.results.map { |row| [row.line_number, row.applied?] }).to eq([[1, true], [2, true]])
    end

    it 'returns the totals before and after (DEC-24)' do
      expect([result.total_before, result.total_after].map(&:to_s)).to eq(%w[150.00 150.00])
    end

    it 'returns the final balances in load order (DEC-15)' do
      expect(result.accounts.map { |held| held.balance.to_s }).to eq(%w[95.00 55.00 0.00])
    end

    it 'returns the output path' do
      expect(result.output_path).to eq('output/day.csv')
    end

    it 'writes the final balances to the output file (DEC-27)' do
      expect(result.then { File.binread('output/day.csv') })
        .to eq("1111234522226789,95.00\n1212343433335665,55.00\n0000123412341234,0.00\n")
    end

    it 'gives the day result to the reporter exactly once' do
      expect(result.then { reporter.printed }).to eq([result])
    end

    it 'calls the reporter after the output file is written (DEC-26)' do
      expect(result.then { reporter.file_existed }).to eq([true])
    end

    it 'logs the start, each applied row with masked numbers, and the end (DEC-28, DEC-29)' do
      expect(result.then { log_lines(logger) })
        .to eq(['INFO Run started: balances balances.csv, transfers transfers.csv',
                'INFO Line 1 applied: ************6789 -> ************5665 10.00',
                'INFO Line 2 applied: ************5665 -> ************6789 5.00',
                'INFO Run ended: processed 2, applied 2, rejected 0'])
    end

    it 'logs an applied amount written 007.50 as 7.50' do
      reader = FakeReader.new([transfers_row(1, '1111234522226789', '1212343433335665', '007.50')])
      day(transfers_reader: reader).call('balances.csv', 'transfers.csv', 'output/day.csv')
      expect(log_lines(logger)).to include('INFO Line 1 applied: ************6789 -> ************5665 7.50')
    end
  end

  describe '#call with the paths it is given' do
    def absolute(name)
      File.join(Dir.pwd, name)
    end

    it 'names the paths as given in the Run started line' do
      day.call(absolute('balances.csv'), absolute('transfers.csv'), absolute('output/day.csv'))
      expect(log_lines(logger).first)
        .to eq("INFO Run started: balances #{absolute('balances.csv')}, transfers #{absolute('transfers.csv')}")
    end

    it 'keeps the output path as given' do
      expect(day.call('balances.csv', 'transfers.csv', absolute('output/day.csv')).output_path)
        .to eq(absolute('output/day.csv'))
    end

    it 'writes the default output file, named from the run time, when no output path is given (DEC-27, DEC-30)' do
      day.call('balances.csv', 'transfers.csv')
      expect(File.file?('output/final_balances_2026-11-07_143005.csv')).to be(true)
    end

    it 'asks the balances reader with the balances path' do
      expect(result.then { balances_reader.paths }).to eq(['balances.csv'])
    end

    it 'asks the transfers reader with the transfers path' do
      expect(result.then { transfers_reader.paths }).to eq(['transfers.csv'])
    end
  end

  describe '#call when the balances file cannot be read' do
    let(:error) { UnreadableFile.cannot_open('balances.csv', Errno::EACCES.new) }
    let(:balances_reader) { FakeReader.new([], error: error) }

    it 'lets the error through unchanged (DEC-12)' do
      expect { result }.to raise_error(be(error))
    end

    it 'reads no transfer before the balances are loaded (DEC-12)' do
      attempt(UnreadableFile) { result }
      expect(transfers_reader.paths).to eq([])
    end
  end

  describe '#call with rejected rows' do
    def rows(*lines)
      lines.each.with_index(1).map { |line, number| transfers_row(number, *line.split(',', -1)) }
    end

    def day_with(transfer_rows, unreadable_at: nil, **changed)
      reader = FakeReader.new(transfer_rows, unreadable_at: unreadable_at)
      day(transfers_reader: reader, **changed).call('balances.csv', 'transfers.csv', 'output/day.csv')
    end

    def reasons(*lines)
      day_with(rows(*lines)).results.map(&:reason)
    end

    def balances_after(*lines)
      day_with(rows(*lines)).accounts.map { |held| held.balance.to_s }
    end

    def logged(transfer_rows)
      day_with(transfer_rows)
      log_lines(logger)
    end

    {
      '12345,1212343433335665,10.00' => :invalid_account_number,
      '1111234522226789,12345,10.00' => :invalid_account_number,
      '1111234522226789,1212343433335665,abc' => :invalid_amount,
      '1111234522226789,1212343433335665,0' => :invalid_amount,
      '1212343433335665,1212343433335665,5.00' => :same_account,
      '9999888877776666,1111234522226789,10.00' => :unknown_account,
      '1111234522226789,9999888877776666,10.00' => :unknown_account,
      '1111234522226789,1212343433335665,100.01' => :insufficient_funds
    }.each do |line, code|
      it "rejects #{line} as #{code} (DEC-19)" do
        expect(reasons(line)).to eq([code])
      end
    end

    it 'builds the values in field order: 12345,1212343433335665,abc is invalid_account_number (FR-014, DEC-19)' do
      expect(reasons('12345,1212343433335665,abc')).to eq([:invalid_account_number])
    end

    ['1111234522226789', '1111234522226789,1212343433335665', '1111234522226789,1212343433335665,10.00,x',
     '9999888877776666,1111234522226789'].each do |line|
      it "rejects #{line} as malformed_row without building any value (DEC-19)" do
        expect(reasons(line)).to eq([:malformed_row])
      end
    end

    it 'carries the header hint into the rejected result (DEC-06)' do
      header = transfers_row(1, 'from', 'to', 'amount', header_hint: CsvRows::HEADER_HINT)
      expect(day_with([header]).results.first.header_hint).to eq(CsvRows::HEADER_HINT)
    end

    it 'changes no balance for a rejected transfer and processes the next row (DEC-14, DEC-18, AC-03.2)' do
      expect(balances_after('1111234522226789,1212343433335665,90.00', '1111234522226789,1212343433335665,100.01',
                            '1212343433335665,1111234522226789,5.00')).to eq(%w[15.00 135.00 0.00])
    end

    describe 'with the rows of AC-07.1' do
      let(:retry_rows) do
        ['0000123412341234,1212343433335665,20.00', '1111234522226789,0000123412341234,20.00',
         '1111234522226789,0000123412341234,20.00']
      end

      it 'rejects line 1 once, with no retry, and applies both repeats (DEC-15, DEC-16)' do
        expect(reasons(*retry_rows)).to eq([:insufficient_funds, nil, nil])
      end

      it 'gives the final balances of AC-07.1 (DEC-15, DEC-16)' do
        expect(balances_after(*retry_rows)).to eq(%w[60.00 50.00 40.00])
      end
    end

    it 'logs a rejected row as a warn line with masked numbers (DEC-28, DEC-29)' do
      expect(logged(rows('1111234522226789,1212343433335665,10.00', '1111234522226789,1212343433335665,100.01')))
        .to include('WARN Line 2 rejected: ************6789 -> ************5665 100.01 insufficient_funds')
    end

    {
      '12345,1212343433335665,10.00' => '*2345 -> ************5665 10.00 invalid_account_number',
      'from,1212343433335665,10.00' => '**** -> ************5665 10.00 invalid_account_number',
      ',1212343433335665,10.00' => '**** -> ************5665 10.00 invalid_account_number',
      '1111-2345-2222-6789,1212343433335665,10.00' => '***************6789 -> ************5665 10.00 ' \
                                                      'invalid_account_number'
    }.each do |line, shown|
      it "masks the values of #{line} that are not account numbers (DEC-29, AC-09.6)" do
        expect(logged(rows(line))).to include("WARN Line 1 rejected: #{shown}")
      end
    end

    it 'logs an empty amount as "" (AC-02.2)' do
      expect(logged(rows(',,'))).to include('WARN Line 1 rejected: **** -> **** "" invalid_account_number')
    end

    it 'logs the two fields of a row with 2 fields by position (item 8)' do
      expect(logged([transfers_row(4, '1111234522226789', '1212343433335665')]))
        .to include('WARN Line 4 rejected: ************6789 -> ************5665 malformed_row')
    end

    it 'logs the one field of a row with 1 field (item 8)' do
      expect(logged(rows('1111234522226789'))).to include('WARN Line 1 rejected: ************6789 malformed_row')
    end

    it 'logs only the first three fields of a row with 4 fields (item 8)' do
      expect(logged(rows('1111234522226789,1212343433335665,1,000.00')))
        .to include('WARN Line 1 rejected: ************6789 -> ************5665 1 malformed_row')
    end

    it 'never logs the header hint (FR-021)' do
      header = transfers_row(1, 'from', 'to', 'amount', header_hint: CsvRows::HEADER_HINT)
      expect(logged([header])).to include('WARN Line 1 rejected: **** -> **** amount invalid_account_number')
    end

    it 'logs only warn and error lines at warn level (DEC-28)' do
      warn_logger = memory_logger(Logger::WARN)
      day_with(rows('1111234522226789,1212343433335665,10.00', '12345,1212343433335665,10.00'), logger: warn_logger)
      expect(log_lines(warn_logger)).to eq(['WARN Line 2 rejected: *2345 -> ************5665 10.00 ' \
                                            'invalid_account_number'])
    end

    it 'counts each reason at the end of the run in DEC-19 order (DEC-19, DEC-28)' do
      mixed_rows = rows('1111234522226789,1212343433335665,30.00', '1111234522226789,1212343433335665,90.00',
                        '1212343433335665,9999888877776666,10.00', '1111234522226789,0000123412341234,70.00',
                        '1212343433335665,1212343433335665,5.00')
      expect(logged(mixed_rows).last).to eq('INFO Run ended: processed 5, applied 2, rejected 3 ' \
                                            '(same_account 1, unknown_account 1, insufficient_funds 1)')
    end
  end

  describe '#call when every row is rejected' do
    let(:transfers_reader) do
      FakeReader.new([transfers_row(1, 'from', 'to', 'amount', header_hint: CsvRows::HEADER_HINT)])
    end

    it 'still returns a day result (DEC-21)' do
      expect(result).to be_a(DayResult)
    end

    it 'still writes the output file (DEC-21)' do
      expect(result.then { File.file?('output/day.csv') }).to be(true)
    end

    it 'still calls the reporter once (DEC-21)' do
      expect(result.then { reporter.printed.size }).to eq(1)
    end

    it 'ends the log with the rejected line, the warning and the counts (DEC-21, DEC-28)' do
      expect(result.then { log_lines(logger).last(3) })
        .to eq(['WARN Line 1 rejected: **** -> **** amount invalid_account_number',
                'WARN All transfers were rejected; check this is the right file.',
                'INFO Run ended: processed 1, applied 0, rejected 1 (invalid_account_number 1)'])
    end
  end

  describe '#call when the transfers file has no rows' do
    let(:transfers_reader) { FakeReader.new([]) }

    it 'stops with NoTransfers naming the path as given (DEC-20)' do
      expect { result }.to raise_error(NoTransfers, 'the transfers file has no transfers: transfers.csv')
    end

    it 'gives the stop reason transfers file has no transfers (P8)' do
      expect { result }.to raise_error(having_attributes(stop_reason: 'transfers file has no transfers'))
    end

    it 'writes no output file (DEC-20)' do
      attempt(NoTransfers) { result }
      expect(File.exist?('output/day.csv')).to be(false)
    end

    it 'never calls the reporter (DEC-20)' do
      attempt(NoTransfers) { result }
      expect(reporter.printed).to eq([])
    end

    it 'logs the start and no Run ended (DEC-28, item 20)' do
      attempt(NoTransfers) { result }
      expect(log_lines(logger)).to eq(['INFO Run started: balances balances.csv, transfers transfers.csv'])
    end
  end

  describe '#call when the transfers file cannot be read past a line' do
    let(:transfers_reader) do
      FakeReader.new([transfers_row(1, '1111234522226789', '1212343433335665', '100.01')], unreadable_at: 2)
    end

    it 'stops with UnreadableFile (DEC-04, AC-02.5)' do
      expect { result }.to raise_error(UnreadableFile, /from line 2/)
    end

    it 'has logged the warn line of the row read before it (AC-02.5, item 20)' do
      attempt(UnreadableFile) { result }
      expect(log_lines(logger))
        .to include('WARN Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds')
    end

    it 'writes no output file (DEC-04)' do
      attempt(UnreadableFile) { result }
      expect(File.exist?('output/day.csv')).to be(false)
    end

    it 'never calls the reporter (DEC-04)' do
      attempt(UnreadableFile) { result }
      expect(reporter.printed).to eq([])
    end

    it 'logs no Run ended (item 20)' do
      attempt(UnreadableFile) { result }
      expect(log_lines(logger).grep(/Run ended/)).to eq([])
    end
  end

  describe '#call when the total of all balances changes (AC-08.5)' do
    subject(:call_day) do
      day(balances_reader: sample_reader('mable_account_balances.csv', 2),
          transfers_reader: sample_reader('mable_transactions.csv', 3),
          repository: ChangingTotalRepository.new(AccountRepository.new)).call('b.csv', 't.csv', 'output/day.csv')
    end

    def sample_reader(name, field_count)
      rows = File.readlines(fixture_path('sample', name), chomp: true).each.with_index(1).map do |line, number|
        Row.new(line_number: number, fields: line.split(','), expected_size: field_count)
      end
      FakeReader.new(rows)
    end

    it 'stops with TotalChanged naming both totals (DEC-24)' do
      expect { call_day }.to raise_error(TotalChanged, 'the total of all balances changed from 66750.00 to 66749.00. ' \
                                                       'No output file was written.')
    end

    it 'gives the stop reason total of all balances changed (P8)' do
      expect { call_day }.to raise_error(having_attributes(stop_reason: 'total of all balances changed'))
    end

    describe 'after the stop' do
      before { attempt(TotalChanged) { call_day } }

      it 'writes no output file (DEC-24)' do
        expect(File.exist?('output/day.csv')).to be(false)
      end

      it 'never calls the reporter (DEC-24)' do
        expect(reporter.printed).to eq([])
      end
    end
  end

  describe '#call when the output file cannot be written' do
    let(:error) { OutputNotWritable.new('output/day.csv', Errno::EACCES.new) }
    let(:writer) { instance_double(FinalBalancesCsvWriter) }

    before { allow(writer).to receive(:write).and_raise(error) }

    it 'lets the error through unchanged (DEC-25)' do
      expect { day(writer: writer).call('b.csv', 't.csv', 'output/day.csv') }.to raise_error(be(error))
    end

    it 'never calls the reporter (DEC-25)' do
      attempt(OutputNotWritable) { day(writer: writer).call('b.csv', 't.csv', 'output/day.csv') }
      expect(reporter.printed).to eq([])
    end
  end

  describe '.new' do
    it 'raises KeyError when a part is left out' do
      expect { described_class.new(**parts.except(:logger)) }.to raise_error(KeyError)
    end
  end
end
