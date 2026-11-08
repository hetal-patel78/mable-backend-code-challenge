# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner, '#run' do
  describe 'with all rejected' do
    subject(:run) do
      run_command('balances.csv', 'transfers.csv', 'output/final_balances_2026-11-07_143005.csv',
                  files: { 'balances.csv' => fixture_path('acceptance', 'balances.csv'),
                           'transfers.csv' => fixture_path('acceptance', 'all_rejected_transfers.csv') })
    end

    let(:ac_02_3_stderr) do
      <<~STDERR
        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** amount invalid_account_number
        W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
      STDERR
    end

    it "prints exactly AC-02.3's report on standard output (DEC-06, DEC-21)" do
      expect(run.stdout).to eq(template_r(line: '  Line 1  rejected  from -> to  amount  invalid_account_number: ' \
                                                'This looks like a header row; files must not have a header.',
                                          reason: 'invalid_account_number'))
    end

    it "writes exactly AC-02.3's two warn lines on standard error (DEC-21, DEC-28)" do
      expect(run.stderr).to match(stream_pattern(ac_02_3_stderr))
    end

    it 'exits with status 0 (AC-09.8, DEC-25)' do
      expect(run.status).to eq(0)
    end

    it 'writes the balances unchanged to the output file, each line ending with LF (DEC-21, DEC-27)' do
      expect(run.output_file).to eq("1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n")
    end
  end
end
