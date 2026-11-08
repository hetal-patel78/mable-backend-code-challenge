# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner, '#run' do
  describe 'with sample files' do
    subject(:run) do
      run_command('data/mable_account_balances.csv', 'data/mable_transactions.csv',
                  'output/final_balances_2026-11-07_143005.csv', files: sample_files)
    end

    let(:sample_files) do
      %w[mable_account_balances.csv mable_transactions.csv].to_h do |name|
        ["data/#{name}", fixture_path('sample', name)]
      end
    end

    it 'prints exactly the report of AC-08.1 on standard output (DEC-26, DEC-35)' do
      expect(run.stdout).to eq(sample_report)
    end

    it 'writes nothing on standard error' do
      expect(run.stderr).to eq('')
    end

    it 'exits with status 0 (DEC-25)' do
      expect(run.status).to eq(0)
    end

    it 'writes exactly the expected final balances to the output file (DEC-27, DEC-35)' do
      expect(run.output_file).to eq(
        "1111234522226789,4820.50\n1111234522221234,9974.40\n2222123433331212,1550.00\n" \
        "1212343433335665,1725.60\n3212343433335755,48679.50\n"
      )
    end
  end
end
