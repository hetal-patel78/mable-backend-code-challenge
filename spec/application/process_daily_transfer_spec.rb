# frozen_string_literal: true

require 'application/process_daily_transfer'
require 'domain/account_repository'
require 'infrastructure/errors'
require 'infrastructure/final_balances_csv_writer'

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

  describe '.new' do
    it 'raises KeyError when a part is left out' do
      expect { described_class.new(**parts.except(:logger)) }.to raise_error(KeyError)
    end
  end
end
