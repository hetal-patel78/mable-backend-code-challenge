# frozen_string_literal: true

require 'infrastructure/balances_csv_reader'

RSpec.describe BalancesCsvReader do
  around { |example| in_temp_folder { example.run } }

  subject(:reader) { described_class.new }

  def rows_of(path)
    rows = []
    reader.each_row(path) { |row| rows << row }
    rows
  end

  before { write_file('balances.csv', "1111234522226789,100.00\n1212343433335665,abc,9\n") }

  it 'expects 2 fields in a row (DEC-04)' do
    expect(described_class::FIELD_COUNT).to eq(2)
  end

  it 'gives rows that expect 2 fields' do
    expect(rows_of('balances.csv').map(&:expected_size)).to eq([2, 2])
  end

  it 'does not mark a row of 2 fields' do
    expect(rows_of('balances.csv').first.wrong_field_count?).to be(false)
  end

  it 'marks a row of 3 fields as the wrong field count (DEC-04)' do
    expect(rows_of('balances.csv').last.wrong_field_count?).to be(true)
  end

  it 'reads the path it is given, so one reader reads two files' do
    write_file('other.csv', "0000123412341234,0.00\n")
    expect([rows_of('balances.csv').size, rows_of('other.csv').size]).to eq([2, 1])
  end
end
