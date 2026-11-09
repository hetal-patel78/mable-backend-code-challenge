# frozen_string_literal: true

# The spec's report templates A and R, AC-08.1's report and its output file, each exactly as the spec prints it.
module ReportTemplates
  DEFAULT_OUTPUT_FILE = 'output/final_balances_2026-11-07_143005.csv'

  def template_a(transfer:, balances:, openings: %w[100.00 50.00 0.00], output_file: DEFAULT_OUTPUT_FILE)
    <<~REPORT
      Transfers
        Line 1  applied  #{transfer}

      #{template_summary(applied: 1)}

      #{template_balances(openings, balances)}

      Output file: #{output_file}
    REPORT
  end

  def template_r(line:, reason:, output_file: DEFAULT_OUTPUT_FILE)
    <<~REPORT
      Transfers
        #{line.lstrip}

      #{template_summary(applied: 0, reason: reason)}

      Warning: All transfers were rejected; check this is the right file.

      Final balances
        Account           Opening  Closing
        1111234522226789   100.00   100.00
        1212343433335665    50.00    50.00
        0000123412341234     0.00     0.00

      Output file: #{output_file}
    REPORT
  end

  def sample_report(output_file: DEFAULT_OUTPUT_FILE)
    <<~REPORT
      Transfers
        Line 1  applied  1111234522226789 -> 1212343433335665  500.00
        Line 2  applied  3212343433335755 -> 2222123433331212  1000.00
        Line 3  applied  3212343433335755 -> 1111234522226789  320.50
        Line 4  applied  1111234522221234 -> 1212343433335665  25.60

      Summary
        Processed: 4
        Applied: 4
        Rejected: 0
        Total before: 66750.00
        Total after: 66750.00

      Final balances
        Account            Opening   Closing
        1111234522226789   5000.00   4820.50
        1111234522221234  10000.00   9974.40
        2222123433331212    550.00   1550.00
        1212343433335665   1200.00   1725.60
        3212343433335755  50000.00  48679.50

      Output file: #{output_file}
    REPORT
  end

  private

  def template_balances(openings, closings)
    rows = %w[1111234522226789 1212343433335665 0000123412341234].each_with_index.map do |number, index|
      "  #{number}  #{openings[index].rjust(7)}  #{closings[index].rjust(7)}"
    end
    ['Final balances', '  Account           Opening  Closing', *rows].join("\n")
  end

  def template_summary(applied:, reason: nil)
    lines = ['Summary', '  Processed: 1', "  Applied: #{applied}", "  Rejected: #{1 - applied}"]
    lines << "    #{reason}: 1" if reason
    (lines + ['  Total before: 150.00', '  Total after: 150.00']).join("\n")
  end
end

RSpec.configure do |config|
  config.include ReportTemplates
  config.extend ReportTemplates
end
