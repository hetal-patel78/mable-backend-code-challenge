# frozen_string_literal: true

require 'infrastructure/transfers_csv_reader'
require 'application/errors'

RSpec.describe TransfersCsvReader do
  subject(:reader) { described_class.new }

  around { |example| in_temp_folder { example.run } }

  def rows_of(path)
    rows = []
    reader.each_row(path) { |row| rows << row }
    rows
  end

  def lines_given_and_error_line(path)
    given = []
    reader.each_row(path) { |row| given << row.line_number }
    [given, nil]
  rescue UnreadableFile => e
    [given, e.line_number]
  end

  it 'expects 3 fields in a row (DEC-04)' do
    expect(described_class::FIELD_COUNT).to eq(3)
  end

  it 'gives rows that expect 3 fields' do
    expect(rows_of(fixture_path('reading', 'field_counts.csv')).map(&:expected_size)).to eq([3, 3, 3, 3])
  end

  it 'marks lines 1, 2 and 4 of field_counts.csv as the wrong field count (DEC-19)' do
    rows = rows_of(fixture_path('reading', 'field_counts.csv'))
    expect(rows.select(&:wrong_field_count?).map(&:line_number)).to eq([1, 2, 4])
  end

  it 'gives line 1 to the block before raising UnreadableFile at line 2, one row at a time (DEC-32, DEC-04)' do
    expect(lines_given_and_error_line(fixture_path('reading', 'unclosed_quote.csv'))).to eq([[1], 2])
  end

  it 'raises UnreadableFile at line 1 before any row, not an empty read (DEC-04, DEC-20)' do
    write_file('transfers.csv', %("1111234522226789,1212343433335665,"10.00\n))
    expect(lines_given_and_error_line('transfers.csv')).to eq([[], 1])
  end
end
