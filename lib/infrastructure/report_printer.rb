# frozen_string_literal: true

require_relative '../domain/money'
require_relative '../application/day_result'
require_relative 'display_path'

# Prints the report of a completed day: the transfers, the summary, the final balances and the output file.
class ReportPrinter
  def initialize(output: $stdout, current_folder: Dir.pwd)
    @output = output
    @current_folder = current_folder
  end

  def print(day_result)
    sections = [transfers(day_result), summary(day_result), final_balances(day_result), output_line(day_result)]
    @output.puts(sections.map { |lines| lines.join("\n") }.join("\n\n"))
    nil
  end

  private

  def transfers(day_result)
    ['Transfers', *day_result.results.map { |result| transfer_line(result) }]
  end

  def transfer_line(result)
    from, to, amount = result.fields
    "  Line #{result.line_number}  applied  #{from} -> #{to}  #{Money.amount(amount)}"
  end

  def summary(day_result)
    ['Summary', "  Processed: #{day_result.processed_count}", "  Applied: #{day_result.applied_count}",
     "  Rejected: #{day_result.rejected_count}", "  Total before: #{day_result.total_before}",
     "  Total after: #{day_result.total_after}"]
  end

  def final_balances(day_result)
    ['Final balances', *day_result.accounts.map { |account| "  #{account.number}  #{account.balance}" }]
  end

  def output_line(day_result)
    ["Output file: #{DisplayPath.of(day_result.output_path, @current_folder)}"]
  end
end
