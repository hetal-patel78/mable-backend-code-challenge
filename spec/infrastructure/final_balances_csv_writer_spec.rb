# frozen_string_literal: true

require 'domain/account'
require 'infrastructure/errors'
require 'infrastructure/final_balances_csv_writer'

RSpec.describe FinalBalancesCsvWriter do
  around { |example| in_temp_folder { example.run } }

  let(:accounts) { three_accounts.all }

  def reason_after(prefix)
    /\A#{Regexp.escape(prefix)}.+\z/
  end

  describe '.default_path' do
    it 'names the file from the run time (DEC-27)' do
      expect(described_class.default_path(Time.new(2026, 11, 7, 14, 30, 5)))
        .to eq('output/final_balances_2026-11-07_143005.csv')
    end

    it 'uses leading zeros (DEC-27)' do
      expect(described_class.default_path(Time.new(2026, 1, 2, 9, 5, 7)))
        .to eq('output/final_balances_2026-01-02_090507.csv')
    end

    it 'uses a 24-hour clock (DEC-27)' do
      expect(described_class.default_path(Time.new(2026, 11, 7, 23, 59, 59)))
        .to eq('output/final_balances_2026-11-07_235959.csv')
    end

    it 'gives runs one second apart their own files (AC-09.7)' do
      times = [Time.new(2026, 11, 7, 14, 30, 5), Time.new(2026, 11, 7, 14, 30, 6)]
      expect(times.map { |time| described_class.default_path(time) })
        .to eq(%w[output/final_balances_2026-11-07_143005.csv output/final_balances_2026-11-07_143006.csv])
    end
  end

  describe '#write' do
    it 'writes each account in load order, 2 decimal places, no header, LF only (DEC-27)' do
      described_class.new.write(accounts, 'out/day1.csv')
      expect(File.binread('out/day1.csv'))
        .to eq("1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n")
    end

    it 'creates missing folders (DEC-27, AC-08.3)' do
      described_class.new.write(accounts, 'out/new/day1.csv')
      expect(File.file?('out/new/day1.csv')).to be(true)
    end

    it 'writes to the path it is given' do
      described_class.new.write(accounts, 'day2.csv')
      expect(Dir.children('.')).to eq(['day2.csv'])
    end

    it 'returns nil' do
      expect(described_class.new.write(accounts, 'day1.csv')).to be_nil
    end
  end

  describe '#write when the file cannot be written (DEC-25)' do
    def write_to(path, written = accounts)
      described_class.new.write(written, path)
    end

    it 'stops with OutputNotWritable when a file appeared at the path' do
      write_file('out/day1.csv', 'kept')
      expect { write_to('out/day1.csv') }
        .to raise_error(OutputNotWritable, reason_after('cannot write output file out/day1.csv: '))
    end

    it 'leaves a file that appeared at the path unchanged' do
      write_file('out/day1.csv', 'kept')
      attempt(OutputNotWritable) { write_to('out/day1.csv') }
      expect(File.binread('out/day1.csv')).to eq('kept')
    end

    it 'stops with OutputNotWritable when the path is a folder' do
      Dir.mkdir('out')
      expect { write_to('out') }.to raise_error(OutputNotWritable, reason_after('cannot write output file out: '))
    end

    it 'leaves the folder at the path in place' do
      Dir.mkdir('out')
      attempt(OutputNotWritable) { write_to('out') }
      expect(File.directory?('out')).to be(true)
    end

    it 'stops with OutputNotWritable when a missing folder cannot be created (item 21)' do
      write_file('blocker', '')
      expect { write_to('blocker/sub/day1.csv') }
        .to raise_error(OutputNotWritable, reason_after('cannot write output file blocker/sub/day1.csv: '))
    end

    it 'leaves no output file when a missing folder cannot be created (item 21)' do
      write_file('blocker', '')
      attempt(OutputNotWritable) { write_to('blocker/sub/day1.csv') }
      expect(File.exist?('blocker/sub/day1.csv')).to be(false)
    end

    it 'gives the stop reason cannot write output file (P8)' do
      Dir.mkdir('out')
      expect { write_to('out') }.to raise_error(having_attributes(stop_reason: 'cannot write output file'))
    end
  end

  describe '#write when writing fails partway (P22)' do
    let(:failing_account) { instance_double(Account, balance: balance('50.00')) }

    before { allow(failing_account).to receive(:number).and_raise(Errno::ENOSPC) }

    def write_partway
      described_class.new.write([accounts.first, failing_account], 'out/day1.csv')
    end

    it 'stops with OutputNotWritable' do
      expect { write_partway }
        .to raise_error(OutputNotWritable, reason_after('cannot write output file out/day1.csv: '))
    end

    it 'deletes the partial file it created (DEC-27)' do
      attempt(OutputNotWritable) { write_partway }
      expect(File.exist?('out/day1.csv')).to be(false)
    end
  end
end
