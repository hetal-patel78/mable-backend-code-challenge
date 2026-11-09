# frozen_string_literal: true

require_relative '../domain/account'
require_relative '../domain/account_number'
require_relative '../domain/errors'
require_relative '../domain/money'
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
    # An error with no line number is about the whole file and is raised. One with a line number stops reading there
    # and becomes the last problem, reported with the problems found before it.
    raise unless e.line_number

    @problems << at_line(e.line_number, e.line_problem)
  end

  def load_row(row)
    row_problems = row.wrong_field_count? ? [field_count_problem(row)] : parse(row)
    @problems.concat(row_problems.map { |problem| at_line(row.line_number, problem) })
  end

  def field_count_problem(row)
    with_hint(row, "expected #{row.expected_size} fields, found #{row.fields.size}")
  end

  def parse(row)
    number_text, balance_text = row.fields
    problems = []
    # Both fields are checked, even when the first is invalid, so one row can give two problems.
    number = account_number(row, number_text, problems)
    balance = opening_balance(balance_text, problems)
    add(number, balance, row.line_number) if problems.empty?
    problems
  end

  def account_number(row, text, problems)
    number = AccountNumber.new(text)
    problems << duplicate(number) if @repository.include?(number)
    number
  rescue InvalidAccountNumber => e
    problems << with_hint(row, e.message)
    nil
  end

  def duplicate(number)
    "#{DuplicateAccount.new(number).message} (first on line #{@first_lines.fetch(number)})"
  end

  def opening_balance(text, problems)
    balance = Money.balance(text)
    Account.check_opening_balance(balance)
    balance
  rescue InvalidAmount, NegativeBalance => e
    problems << e.message
    nil
  end

  def with_hint(row, problem)
    row.header_hint ? "#{problem}. #{row.header_hint}" : problem
  end

  def add(number, balance, line_number)
    @repository.add(Account.new(number, balance))
    @first_lines[number] = line_number
  end

  def at_line(line_number, problem)
    "Line #{line_number}: #{problem}"
  end
end
