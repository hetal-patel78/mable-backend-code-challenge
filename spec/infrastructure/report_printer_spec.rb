# frozen_string_literal: true

require 'infrastructure/report_printer'

RSpec.describe ReportPrinter do
  let(:project) { File.join(Dir.tmpdir, 'report_printer', 'project') }
  let(:stream) { StringIO.new }
  let(:sample_output_path) { File.join(project, 'output', 'final_balances_2026-11-07_143005.csv') }

  def sample_day(output_path)
    rows = [%w[1111234522226789 1212343433335665 500.00], %w[3212343433335755 2222123433331212 1000.00],
            %w[3212343433335755 1111234522226789 320.50], %w[1111234522221234 1212343433335665 25.60]]
    finals = { '1111234522226789' => '4820.50', '1111234522221234' => '9974.40', '2222123433331212' => '1550.00',
               '1212343433335665' => '1725.60', '3212343433335755' => '48679.50' }
    day_result(rows, finals.map { |number, closing| account(number, closing) }, output_path)
  end

  def day_result(rows, accounts, output_path)
    results = rows.each.with_index(1).map { |fields, line| TransferResult.applied(line_number: line, fields: fields) }
    DayResult.new(results: results, total_before: balance('66750.00'), total_after: balance('66750.00'),
                  accounts: accounts, output_path: output_path)
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
end
