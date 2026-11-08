# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner, '#run' do
  describe 'with invalid balances' do
    subject(:run) do
      run_command('balances.csv', 'transfers.csv', 'output/final_balances_2026-11-07_143005.csv',
                  files: { 'balances.csv' => fixture_path('acceptance', 'invalid_balances.csv'),
                           'transfers.csv' => fixture_path('acceptance', 'mixed_rejections_transfers.csv') })
    end

    let(:ac_01_4_stderr) do
      <<~STDERR
        Error: the balances file is invalid (5 problems):
          Line 3: account number "12345" must be exactly 16 digits
          Line 4: expected 2 fields, found 3
          Line 5: account 1111234522226789 appears more than once (first on line 1)
          Line 6: balance "-5.00" must not be negative
          Line 7: balance "1.234" has more than 2 decimal places
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 5 problems
      STDERR
    end

    it 'prints nothing on standard output' do
      expect(run.stdout).to eq('')
    end

    it 'writes exactly the problems of AC-01.4 and the stop log line on standard error (DEC-12)' do
      expect(run.stderr).to match(stream_pattern(ac_01_4_stderr))
    end

    it 'exits with status 1 (DEC-25)' do
      expect(run.status).to eq(1)
    end

    it 'writes no output file (SC-004)' do
      expect(run.output_file).to be_nil
    end
  end
end
