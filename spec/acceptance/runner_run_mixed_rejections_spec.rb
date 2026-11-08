# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner, '#run' do
  describe 'with mixed rejections' do
    subject(:run) do
      run_command('balances.csv', 'transfers.csv', 'output/final_balances_2026-11-07_143005.csv',
                  files: { 'balances.csv' => fixture_path('acceptance', 'balances.csv'),
                           'transfers.csv' => fixture_path('acceptance', 'mixed_rejections_transfers.csv') })
    end

    let(:ac_08_2_stdout) do
      <<~STDOUT
        Transfers
          Line 1  applied  1111234522226789 -> 1212343433335665  30.00
          Line 2  rejected  1111234522226789 -> 1212343433335665  90.00  insufficient_funds
          Line 3  rejected  1212343433335665 -> 9999888877776666  10.00  unknown_account
          Line 4  applied  1111234522226789 -> 0000123412341234  70.00
          Line 5  rejected  1212343433335665 -> 1212343433335665  5.00  same_account

        Summary
          Processed: 5
          Applied: 2
          Rejected: 3
            same_account: 1
            unknown_account: 1
            insufficient_funds: 1
          Total before: 150.00
          Total after: 150.00

        Final balances
          1111234522226789  0.00
          1212343433335665  80.00
          0000123412341234  70.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
    end

    let(:ac_08_2_stderr) do
      <<~STDERR
        W, [<timestamp> #<pid>]  WARN -- : Line 2 rejected: ************6789 -> ************5665 90.00 insufficient_funds
        W, [<timestamp> #<pid>]  WARN -- : Line 3 rejected: ************5665 -> ************6666 10.00 unknown_account
        W, [<timestamp> #<pid>]  WARN -- : Line 5 rejected: ************5665 -> ************5665 5.00 same_account
      STDERR
    end

    it "prints exactly AC-08.2's report on standard output (DEC-14, DEC-19, DEC-26)" do
      expect(run.stdout).to eq(ac_08_2_stdout)
    end

    it "writes exactly AC-08.2's three warn lines on standard error (DEC-28)" do
      expect(run.stderr).to match(stream_pattern(ac_08_2_stderr))
    end

    it 'exits with status 0 (AC-09.8, DEC-25)' do
      expect(run.status).to eq(0)
    end

    it 'writes the final balances to the output file, each line ending with LF (DEC-27)' do
      expect(run.output_file).to eq("1111234522226789,0.00\n1212343433335665,80.00\n0000123412341234,70.00\n")
    end
  end
end
