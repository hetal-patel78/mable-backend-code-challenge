# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner, '#run' do
  describe 'with wrong arguments' do
    subject(:run) { run_command('balances.csv', files: {}) }

    it 'prints nothing on standard output' do
      expect(run.stdout).to eq('')
    end

    it 'writes exactly the two usage lines on standard error, with no log line (DEC-22)' do
      expect(run.stderr).to eq("Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]\n" \
                               "With no arguments, runs the sample files in data/.\n")
    end

    it 'exits with status 1 (DEC-25)' do
      expect(run.status).to eq(1)
    end
  end
end
