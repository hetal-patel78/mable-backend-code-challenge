# frozen_string_literal: true

require_relative '../domain/money'

# The text of each log line of the day's run except the all-rejected warning, with account values masked.
class LogMessages
  def self.run_started(balances_path, transfers_path)
    "Run started: balances #{balances_path}, transfers #{transfers_path}"
  end

  def self.applied(result)
    from, to, amount = result.fields
    "Line #{result.line_number} applied: #{mask(from)} -> #{mask(to)} #{Money.amount(amount)}"
  end

  def self.rejected(result)
    from, to, amount = result.fields
    shown = [from && mask(from), to && "-> #{mask(to)}", amount && (amount.empty? ? '""' : amount)].compact
    "Line #{result.line_number} rejected: #{[*shown, result.reason].join(' ')}"
  end

  def self.run_ended(day_result)
    text = "Run ended: processed #{day_result.processed_count}, applied #{day_result.applied_count}, " \
           "rejected #{day_result.rejected_count}"
    counts = day_result.rejected_counts.map { |code, count| "#{code} #{count}" }
    counts.empty? ? text : "#{text} (#{counts.join(', ')})"
  end

  def self.mask(value)
    value.length <= 4 ? '****' : ('*' * (value.length - 4)) + value[-4..]
  end
end
