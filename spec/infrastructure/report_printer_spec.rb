# frozen_string_literal: true

require 'infrastructure/report_printer'
require 'application/day_result'
require 'application/transfer_result'
require 'infrastructure/csv_rows'

RSpec.describe ReportPrinter do
  let(:project) { File.join(Dir.tmpdir, 'report_printer', 'project') }
  let(:stream) { StringIO.new }
  let(:sample_output_path) { File.join(project, 'output', 'final_balances_2026-11-07_143005.csv') }

  def sample_day(output_path)
    rows = [%w[1111234522226789 1212343433335665 500.00], %w[3212343433335755 2222123433331212 1000.00],
            %w[3212343433335755 1111234522226789 320.50], %w[1111234522221234 1212343433335665 25.60]]
    balances = { '1111234522226789' => %w[5000.00 4820.50], '1111234522221234' => %w[10000.00 9974.40],
                 '2222123433331212' => %w[550.00 1550.00], '1212343433335665' => %w[1200.00 1725.60],
                 '3212343433335755' => %w[50000.00 48679.50] }
    day_result(rows, balances, output_path)
  end

  def day_result(rows, balances, output_path)
    results = rows.each.with_index(1).map { |fields, line| TransferResult.applied(line_number: line, fields: fields) }
    DayResult.new(results: results, total_before: balance('66750.00'), total_after: balance('66750.00'),
                  opening_balances: openings_of(balances), accounts: accounts_of(balances), output_path: output_path)
  end

  def openings_of(balances)
    balances.to_h { |number, (opening, _)| [account_number(number), balance(opening)] }
  end

  def accounts_of(balances)
    balances.map { |number, (_, closing)| account(number, closing) }
  end

  def printed(day, folder = project)
    described_class.new(output: stream, current_folder: folder).print(day)
    stream.string
  end

  describe '#print' do
    it 'prints exactly the report of AC-08.1 for the sample day (DEC-26, DEC-35)' do
      expect(printed(sample_day(sample_output_path))).to eq(sample_report)
    end

    it 'shows an applied amount written 10 with 2 decimal places' do
      day = day_result([%w[1111234522226789 1212343433335665 10]], [], sample_output_path)
      expect(printed(day).lines[1]).to eq("  Line 1  applied  1111234522226789 -> 1212343433335665  10.00\n")
    end

    it 'shows an applied amount written 007.50 as 7.50' do
      day = day_result([%w[1111234522226789 1212343433335665 007.50]], [], sample_output_path)
      expect(printed(day).lines[1]).to eq("  Line 1  applied  1111234522226789 -> 1212343433335665  7.50\n")
    end

    it 'shows an output file in another folder of the parent in full (AC-08.4, DEC-26)' do
      report = printed(sample_day(sample_output_path), File.join(project, 'docs'))
      expect(report.lines.last).to eq("Output file: #{File.expand_path(sample_output_path)}\n")
    end

    it 'shows an output file elsewhere in full (AC-08.4, DEC-26)' do
      report = printed(sample_day(File.expand_path('/day1.csv')), File.join(project, 'docs'))
      expect(report.lines.last).to eq("Output file: #{File.expand_path('/day1.csv')}\n")
    end

    it 'writes nothing to standard error' do
      expect { printed(sample_day(sample_output_path)) }.not_to output.to_stderr
    end
  end

  describe '#print with rejected rows' do
    def rejected(line, fields, reason, hint = nil)
      TransferResult.rejected(line_number: line, fields: fields, reason: reason, header_hint: hint)
    end

    def applied(line, fields)
      TransferResult.applied(line_number: line, fields: fields)
    end

    def day_of(results, closings = %w[100.00 50.00 0.00])
      balances = %w[1111234522226789 1212343433335665 0000123412341234].zip(%w[100.00 50.00 0.00].zip(closings))
      DayResult.new(results: results, total_before: balance('150.00'), total_after: balance('150.00'),
                    opening_balances: openings_of(balances), accounts: accounts_of(balances),
                    output_path: sample_output_path)
    end

    def line_of(result)
      printed(day_of([result])).lines[1]
    end

    let(:ac_02_1_report) do
      <<~REPORT
        Transfers
          Line 1  applied  1111234522226789 -> 1212343433335665  10.00
          Line 4  rejected  malformed_row: 2 fields, expected 3
          Line 5  applied  1212343433335665 -> 1111234522226789  5.00

        Summary
          Processed: 3
          Applied: 2
          Rejected: 1
            malformed_row: 1
          Total before: 150.00
          Total after: 150.00

        Final balances
          Account           Opening  Closing
          1111234522226789   100.00    95.00
          1212343433335665    50.00    55.00
          0000123412341234     0.00     0.00

        Output file: output/final_balances_2026-11-07_143005.csv
      REPORT
    end

    it "prints exactly AC-02.3's report, the warning after the summary (DEC-21)" do
      day = day_of([rejected(1, %w[from to amount], :invalid_account_number, CsvRows::HEADER_HINT)])
      expect(printed(day)).to eq(template_r(line: '  Line 1  rejected  from -> to  amount  invalid_account_number: ' \
                                                  "#{CsvRows::HEADER_HINT}", reason: 'invalid_account_number'))
    end

    it "prints exactly AC-02.1's report, with no warning (DEC-26)" do
      results = [applied(1, %w[1111234522226789 1212343433335665 10.00]),
                 rejected(4, %w[1111234522226789 1212343433335665], :malformed_row),
                 applied(5, %w[1212343433335665 1111234522226789 5.00])]
      expect(printed(day_of(results, %w[95.00 55.00 0.00]))).to eq(ac_02_1_report)
    end

    it 'shows a rejected row with its values as written and its code' do
      expect(line_of(rejected(3, %w[1212343433335665 9999888877776666 10.00], :unknown_account)))
        .to eq("  Line 3  rejected  1212343433335665 -> 9999888877776666  10.00  unknown_account\n")
    end

    it 'shows an empty value as "" (page 10 pick 11)' do
      expect(line_of(rejected(1, ['', '', ''], :invalid_account_number)))
        .to eq(%(  Line 1  rejected  "" -> ""  ""  invalid_account_number\n))
    end

    it 'shows no values for a row with 2 fields (DEC-19)' do
      expect(line_of(rejected(4, %w[1111234522226789 1212343433335665], :malformed_row)))
        .to eq("  Line 4  rejected  malformed_row: 2 fields, expected 3\n")
    end

    it 'shows no values for a row with 1 field (item 8)' do
      expect(line_of(rejected(1, %w[1111234522226789], :malformed_row)))
        .to eq("  Line 1  rejected  malformed_row: 1 fields, expected 3\n")
    end

    it 'shows no values for a row with 4 fields, such as an unquoted 1,000.00 (AC-06.2)' do
      expect(line_of(rejected(5, %w[1111234522226789 1212343433335665 1 000.00], :malformed_row)))
        .to eq("  Line 5  rejected  malformed_row: 4 fields, expected 3\n")
    end

    it 'shows the header hint after a wrong field count (page 10 pick 10, DEC-06)' do
      expect(line_of(rejected(1, %w[from to], :malformed_row, CsvRows::HEADER_HINT)))
        .to eq("  Line 1  rejected  malformed_row: 2 fields, expected 3. #{CsvRows::HEADER_HINT}\n")
    end

    it 'shows the counts per reason in DEC-19 order between Rejected and Total before (AC-08.2)' do
      results = [rejected(2, %w[a b 90.00], :insufficient_funds), rejected(3, %w[a b 10.00], :unknown_account),
                 rejected(5, %w[a a 5.00], :same_account), applied(1, %w[a b 30.00])]
      expect(printed(day_of(results)).lines[9..13].join)
        .to eq("  Rejected: 3\n    same_account: 1\n    unknown_account: 1\n    insufficient_funds: 1\n" \
               "  Total before: 150.00\n")
    end
  end
end
