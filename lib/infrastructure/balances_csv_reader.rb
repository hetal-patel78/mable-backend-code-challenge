# frozen_string_literal: true

require_relative 'csv_rows'

# Reads the balances file one row at a time: an account number and a balance per row.
class BalancesCsvReader
  FIELD_COUNT = 2

  def each_row(path, &)
    CsvRows.new(path, FIELD_COUNT).each(&)
  end
end
