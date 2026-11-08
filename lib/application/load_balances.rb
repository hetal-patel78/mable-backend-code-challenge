# frozen_string_literal: true

require_relative '../domain/account'
require_relative '../domain/account_number'
require_relative '../domain/errors'
require_relative '../domain/money'
require_relative '../infrastructure/errors'
require_relative 'errors'

# Loads every row of the balances file into the repository, in file order, or lists every problem in it.
class LoadBalances
  def initialize(reader, repository)
    @reader = reader
    @repository = repository
  end

  def call(path)
    @problems = []
    @first_lines = {}
    read(path)
    raise InvalidBalancesFile, @problems if @problems.any?
    raise InvalidBalancesFile.no_rows(path) if @first_lines.empty?

    nil
  end

  private

  def read(path)
    @reader.each_row(path) { |row| load_row(row) }
  rescue UnreadableFile => e
    raise unless e.line_number

    @problems << "Line #{e.line_number}: #{e.line_problem}"
  end

  def load_row(row)
    row_problems = problems_of(row)
    return add(row) if row_problems.empty?

    @problems.concat(row_problems.map { |problem| "Line #{row.line_number}: #{problem}" })
  end

  def problems_of(row)
    return [with_hint(row, "expected #{row.expected_size} fields, found #{row.fields.size}")] if row.wrong_field_count?

    [number_problem(row), balance_problem(row.fields[1])].compact
  end

  def number_problem(row)
    number = AccountNumber.new(row.fields[0])
    duplicate(number) if @repository.include?(number)
  rescue InvalidAccountNumber => e
    with_hint(row, e.message)
  end

  def duplicate(number)
    "#{DuplicateAccount.new(number).message} (first on line #{@first_lines.fetch(number.to_s)})"
  end

  def balance_problem(text)
    Account.check_opening_balance(Money.balance(text))
    nil
  rescue InvalidAmount, NegativeBalance => e
    e.message
  end

  def with_hint(row, problem)
    row.header_hint ? "#{problem}. #{row.header_hint}" : problem
  end

  def add(row)
    number = AccountNumber.new(row.fields[0])
    @repository.add(Account.new(number, Money.balance(row.fields[1])))
    @first_lines[number.to_s] = row.line_number
  end
end
