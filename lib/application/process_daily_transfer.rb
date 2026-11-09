# frozen_string_literal: true

require_relative 'load_balances'
require_relative 'log_messages'
require_relative 'day_result'
require_relative 'errors'
require_relative 'transfer_result'
require_relative '../domain/account_number'
require_relative '../domain/errors'
require_relative '../domain/money'
require_relative '../domain/transfer'
require_relative '../domain/transfer_service'
require_relative '../infrastructure/final_balances_csv_writer'

# Runs one day: loads the balances, applies each transfer in file order, writes the output file and reports.
class ProcessDailyTransfer
  # The six parts the day is run with, each given by name.
  Parts = Data.define(:balances_reader, :transfers_reader, :writer, :repository, :reporter, :logger)

  REJECTIONS = {
    InvalidAccountNumber => :invalid_account_number, InvalidAmount => :invalid_amount,
    SameAccount => :same_account, UnknownAccount => :unknown_account, InsufficientFunds => :insufficient_funds
  }.freeze

  def initialize(parts, run_time: Time.now)
    @run_time = run_time
    @balances_reader = parts.balances_reader
    @transfers_reader = parts.transfers_reader
    @writer = parts.writer
    @repository = parts.repository
    @reporter = parts.reporter
    @logger = parts.logger
  end

  def call(balances_path, transfers_path, output_path = nil)
    output_path ||= FinalBalancesCsvWriter.default_path(@run_time)
    @logger.info(LogMessages.run_started(balances_path, transfers_path))
    LoadBalances.new(@balances_reader, @repository).call(balances_path)
    opening_balances = take_opening_balances
    results = apply_transfers(transfers_path)
    day_result = close_day(results, opening_balances, output_path)
    @reporter.print(day_result)
    @logger.info(LogMessages.run_ended(day_result))
    day_result
  end

  private

  def apply_transfers(path)
    service = TransferService.new(@repository)
    results = []
    @transfers_reader.each_row(path) { |row| results << logged(result_of(service, row)) }
    raise NoTransfers, path if results.empty?

    @logger.warn(DayResult::ALL_REJECTED_WARNING) if results.all?(&:rejected?)
    results
  end

  def result_of(service, row)
    return rejected(row, :malformed_row) if row.wrong_field_count?

    from, to, amount = row.fields
    service.apply(Transfer.new(from: AccountNumber.new(from), to: AccountNumber.new(to), amount: Money.amount(amount)))
    TransferResult.applied(line_number: row.line_number, fields: row.fields)
  rescue *REJECTIONS.keys => e
    rejected(row, REJECTIONS.fetch(e.class))
  end

  def rejected(row, reason)
    TransferResult.rejected(line_number: row.line_number, fields: row.fields, reason: reason,
                            header_hint: row.header_hint)
  end

  def logged(result)
    if result.applied?
      @logger.info(LogMessages.applied(result))
    else
      @logger.warn(LogMessages.rejected(result))
    end
    result
  end

  def take_opening_balances
    @repository.all.to_h { |account| [account.number, account.balance] }
  end

  def close_day(results, opening_balances, output_path)
    total_before = opening_balances.values.reduce(:+)
    total_after = @repository.all.map(&:balance).reduce(:+)
    raise TotalChanged.new(total_before, total_after) unless total_after == total_before

    @writer.write(@repository.all, output_path)
    DayResult.new(results: results, total_before: total_before, total_after: total_after,
                  opening_balances: opening_balances, accounts: @repository.all, output_path: output_path)
  end
end
