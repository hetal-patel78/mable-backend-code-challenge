# frozen_string_literal: true

require_relative '../domain/money'
require_relative '../application/day_result'
require_relative 'display_path'
require_relative 'transfers_csv_reader'

# Prints the report of a completed day: the transfers, the summary, the final balances and the output file.
class ReportPrinter
  def initialize(output: $stdout, current_folder: Dir.pwd)
    @output = output
    @current_folder = current_folder
  end

  def print(day_result)
    sections = [transfers(day_result), summary(day_result), warning(day_result), final_balances(day_result),
                output_line(day_result)].compact
    @output.puts(sections.map { |lines| lines.join("\n") }.join("\n\n"))
    nil
  end

  private

  def transfers(day_result)
    ['Transfers', *day_result.results.map { |result| "  Line #{result.line_number}  #{outcome(result)}" }]
  end

  def outcome(result)
    return "applied  #{values(result.fields, Money.amount(result.fields[2]))}" if result.applied?
    return "rejected  #{malformed(result)}" if result.reason == :malformed_row

    "rejected  #{values(result.fields, shown(result.fields[2]))}  #{with_hint(result.reason, ': ', result)}"
  end

  def values(fields, amount)
    "#{shown(fields[0])} -> #{shown(fields[1])}  #{amount}"
  end

  def malformed(result)
    with_hint("malformed_row: #{result.fields.size} fields, expected #{TransfersCsvReader::FIELD_COUNT}", '. ', result)
  end

  def with_hint(text, separator, result)
    result.header_hint ? "#{text}#{separator}#{result.header_hint}" : text
  end

  def shown(value)
    value.empty? ? '""' : value
  end

  def summary(day_result)
    ['Summary', "  Processed: #{day_result.processed_count}", "  Applied: #{day_result.applied_count}",
     "  Rejected: #{day_result.rejected_count}", *day_result.rejected_counts.map { |code, n| "    #{code}: #{n}" },
     "  Total before: #{day_result.total_before}", "  Total after: #{day_result.total_after}"]
  end

  def warning(day_result)
    ["Warning: #{DayResult::ALL_REJECTED_WARNING}"] if day_result.all_rejected?
  end

  def final_balances(day_result)
    ['Final balances', *day_result.accounts.map { |account| "  #{account.number}  #{account.balance}" }]
  end

  def output_line(day_result)
    ["Output file: #{DisplayPath.of(day_result.output_path, @current_folder)}"]
  end
end
