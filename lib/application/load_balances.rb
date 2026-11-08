# frozen_string_literal: true

require_relative '../domain/account'
require_relative '../domain/account_number'
require_relative '../domain/money'

# Loads every row of the balances file into the repository, in file order.
class LoadBalances
  def initialize(reader, repository)
    @reader = reader
    @repository = repository
  end

  def call(path)
    @first_lines = {}
    @reader.each_row(path) { |row| add(row) }
    nil
  end

  private

  def add(row)
    number = AccountNumber.new(row.fields[0])
    @repository.add(Account.new(number, Money.balance(row.fields[1])))
    @first_lines[number.to_s] = row.line_number
  end
end
