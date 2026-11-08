# frozen_string_literal: true

require_relative 'csv_rows'

# Reads the transfers file one row at a time: a from account, a to account and an amount per row.
class TransfersCsvReader
  FIELD_COUNT = 3

  def each_row(path, &)
    CsvRows.new(path, FIELD_COUNT).each(&)
  end
end
