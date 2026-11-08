# frozen_string_literal: true

require_relative 'load_balances'
require_relative 'day_result'
require_relative 'errors'
require_relative '../domain/account_number'
require_relative '../domain/errors'
require_relative '../domain/money'
require_relative '../domain/transfer'
require_relative '../domain/transfer_result'
require_relative '../domain/transfer_service'
require_relative '../infrastructure/final_balances_csv_writer'

# Runs one day: loads the balances, applies each transfer in file order, writes the output file and reports.
class ProcessDailyTransfer
  PARTS = %i[balances_reader transfers_reader writer repository reporter logger].freeze
  REJECTIONS = {
    InvalidAccountNumber => :invalid_account_number, InvalidAmount => :invalid_amount,
    SameAccount => :same_account, UnknownAccount => :unknown_account, InsufficientFunds => :insufficient_funds
  }.freeze

  def initialize(run_time: Time.now, **parts)
    @run_time = run_time
    @balances_reader, @transfers_reader, @writer, @repository, @reporter, @logger =
      PARTS.map { |name| parts.fetch(name) }
  end

  def call(balances_path, transfers_path, output_path = nil)
    output_path ||= FinalBalancesCsvWriter.default_path(@run_time)
    @logger.info("Run started: balances #{balances_path}, transfers #{transfers_path}")
    LoadBalances.new(@balances_reader, @repository).call(balances_path)
    total_before = total
    results = apply_transfers(transfers_path)
    day_result = close_day(results, total_before, output_path)
    @reporter.print(day_result)
    @logger.info(run_ended(day_result))
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
      @logger.info("Line #{result.line_number} applied: #{applied_text(result.fields)}")
    else
      @logger.warn("Line #{result.line_number} rejected: #{[*rejected_fields(result.fields), result.reason].join(' ')}")
    end
    result
  end

  def applied_text(fields)
    from, to, amount = fields
    "#{mask(from)} -> #{mask(to)} #{Money.amount(amount)}"
  end

  def rejected_fields(fields)
    from, to, amount = fields
    [from && mask(from), to && "-> #{mask(to)}", amount && (amount.empty? ? '""' : amount)].compact
  end

  def close_day(results, total_before, output_path)
    total_after = total
    raise TotalChanged.new(total_before, total_after) unless total_after == total_before

    @writer.write(@repository.all, output_path)
    DayResult.new(results: results, total_before: total_before, total_after: total_after,
                  accounts: @repository.all, output_path: output_path)
  end

  def total
    @repository.all.map(&:balance).reduce(:+)
  end

  def run_ended(day_result)
    text = "Run ended: processed #{day_result.processed_count}, applied #{day_result.applied_count}, " \
           "rejected #{day_result.rejected_count}"
    counts = day_result.rejected_counts.map { |code, count| "#{code} #{count}" }
    counts.empty? ? text : "#{text} (#{counts.join(', ')})"
  end

  def mask(value)
    value.length <= 4 ? '****' : ('*' * (value.length - 4)) + value[-4..]
  end
end
