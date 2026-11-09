# frozen_string_literal: true

require_relative 'transfer_result'

# The day's outcome: every transfer result in file order, the totals, the opening balances, the final accounts
# and the output path.
DayResult = Data.define(:results, :total_before, :total_after, :opening_balances, :accounts, :output_path) do
  def processed_count
    results.size
  end

  def applied_count
    results.count(&:applied?)
  end

  def rejected_count
    results.count(&:rejected?)
  end

  def rejected_counts
    tally = results.select(&:rejected?).map(&:reason).tally
    TransferResult::REASON_CODES.select { |code| tally.key?(code) }.to_h { |code| [code, tally[code]] }
  end

  def all_rejected?
    results.any? && results.all?(&:rejected?)
  end
end

DayResult::ALL_REJECTED_WARNING = 'All transfers were rejected; check this is the right file.'
