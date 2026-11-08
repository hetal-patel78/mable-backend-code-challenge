# frozen_string_literal: true

require 'infrastructure/final_balances_csv_writer'

RSpec.describe FinalBalancesCsvWriter do
  around { |example| in_temp_folder { example.run } }

  let(:accounts) { three_accounts.all }

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
end
