# frozen_string_literal: true

require 'infrastructure/runner'

RSpec.describe Runner do
  describe 'FR-01 Load the balances file' do
    describe 'AC-01.1 a valid file is loaded, including leading zeros and a $0.00 balance' do
      subject(:run) { run_scenario }

      it_behaves_like 'a completed run',
                      stdout: template_a(transfer: '1111234522226789 -> 1212343433335665  10.00',
                                         balances: %w[90.00 60.00 0.00])
    end

    describe 'AC-01.2 common CSV forms are accepted' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "\xEF\xBB\xBF\"1111234522226789\", 100.00 \r\n" \
                                                "1212343433335665,50.00\r\n0000123412341234,0.00" })
      end

      it_behaves_like 'a completed run',
                      stdout: template_a(transfer: '1111234522226789 -> 1212343433335665  10.00',
                                         balances: %w[90.00 60.00 0.00])
    end

    describe 'AC-01.3 blank lines are skipped but still counted in line numbers' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1111234522226789,100.00\n\n   \n12345,50.00\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 4: account number "12345" must be exactly 16 digits
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.4 an invalid file reports every problem and stops the run' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1111234522226789,5000.00\n\n12345,100.00\n1212343433335665,abc,9\n" \
                                                "1111234522226789,10.00\n2222123433331212,-5.00\n" \
                                                "3212343433335755,1.234\n" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (5 problems):
          Line 3: account number "12345" must be exactly 16 digits
          Line 4: expected 2 fields, found 3
          Line 5: account 1111234522226789 appears more than once (first on line 1)
          Line 6: balance "-5.00" must not be negative
          Line 7: balance "1.234" has more than 2 decimal places
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 5 problems
      STDERR

      it 'names no account number in the error log line (DEC-28)' do
        expect(run.stderr.lines.grep(/\AE, \[/).join).not_to match(/\d{16}/)
      end
    end

    describe 'AC-01.5 a row with several problems reports each one, in field order' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "12345,abc\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 1: account number "12345" must be exactly 16 digits
          Line 1: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end

    describe 'AC-01.6 1111234522226789,' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1212343433335665,50.00\n1111234522226789,\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 2: balance is empty
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.6 1111234522226789,abc' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1212343433335665,50.00\n1111234522226789,abc\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 2: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.6 1111234522226789,5000.00,x' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1212343433335665,50.00\n1111234522226789,5000.00,x\n" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 2: expected 2 fields, found 3
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.6 ,' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1212343433335665,50.00\n,\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 2: account number "" must be exactly 16 digits
          Line 2: balance is empty
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end

    describe 'AC-01.7 a header row makes the file invalid, with a hint (DEC-06)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "account,balance\n#{Runs::DEFAULT_FILES['balances.csv']}" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 1: account number "account" must be exactly 16 digits. This looks like a header row; files must not have a header.
          Line 1: balance "balance" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end

    describe 'AC-01.7 1111O34522226789,100.00 has no header hint (DEC-06)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1111O34522226789,100.00\n1212343433335665,50.00\n" \
                                                "0000123412341234,0.00\n" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 1: account number "1111O34522226789" must be exactly 16 digits
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.7 account,balance,x has the header hint (DEC-06)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "account,balance,x\n#{Runs::DEFAULT_FILES['balances.csv']}" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 1: expected 2 fields, found 3. This looks like a header row; files must not have a header.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.8 an empty balances file stops the run (DEC-11)' do
      subject(:run) { run_scenario(files: { 'empty.csv' => '' }, arguments: ['empty.csv', 'transfers.csv', output]) }

      let(:output) { Runs::OUTPUT_FILE }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file has no rows: empty.csv
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.8 a balances file of only blank lines stops the run (DEC-05, DEC-11)' do
      subject(:run) do
        run_scenario(files: { 'empty.csv' => "\n  \n\n" }, arguments: ['empty.csv', 'transfers.csv', output])
      end

      let(:output) { Runs::OUTPUT_FILE }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file has no rows: empty.csv
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.9 a balances file that cannot be read past a line (DEC-04, DEC-12)' do
      subject(:run) do
        run_scenario(files: { 'bad.csv' => "1111234522226789,100.00\n1212343433335665,50.00\n12345,100.00\n" \
                                           "0000123412341234,0.00\n\n\n1111234522226789,\"100.00\n" },
                     arguments: ['bad.csv', 'transfers.csv', Runs::OUTPUT_FILE])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 3: account number "12345" must be exactly 16 digits
          Line 7: cannot read bad.csv from this line. Check for an unclosed quote or characters that are not text.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end

    describe 'AC-01.10 a duplicate account is reported even when its balance is invalid (DEC-12, DEC-31)' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1111234522226789,5000.00\n1111234522226789,abc\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 2: account 1111234522226789 appears more than once (first on line 1)
          Line 2: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end

    describe 'AC-01.10 known gap: a first copy with an invalid balance (DEC-12)' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1111234522226789,abc\n1111234522226789,10.00\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 1: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.10 known gap: a first copy with the wrong field count (DEC-12)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1111234522226789,5000.00,x\n1111234522226789,10.00\n" })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 1: expected 2 fields, found 3
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'AC-01.10 known gap: a first copy with a negative balance (DEC-12)' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "1111234522226789,-5.00\n1111234522226789,10.00\n" }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (1 problem):
          Line 1: balance "-5.00" must not be negative
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
      STDERR
    end

    describe 'the balances file is checked before an empty transfers file (DEC-12, DEC-20)' do
      subject(:run) { run_scenario(files: { 'balances.csv' => "12345,abc\n", 'transfers.csv' => '' }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the balances file is invalid (2 problems):
          Line 1: account number "12345" must be exactly 16 digits
          Line 1: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
      STDERR
    end
  end

  describe 'FR-02 Read the transfers file' do
    describe 'AC-02.1 blank lines are skipped; a row with the wrong number of fields is rejected (DEC-05, DEC-19)' do
      subject(:run) do
        run_scenario(files: { 'transfers.csv' => "1111234522226789,1212343433335665,10.00\n\n   \n" \
                                                 "1111234522226789,1212343433335665\n" \
                                                 "1212343433335665,1111234522226789,5.00\n" })
      end

      it_behaves_like 'a completed run', stdout: <<~STDOUT, stderr: <<~STDERR
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
          1111234522226789  95.00
          1212343433335665  55.00
          0000123412341234  0.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
        W, [<timestamp> #<pid>]  WARN -- : Line 4 rejected: ************6789 -> ************5665 malformed_row
      STDERR
    end

    describe 'AC-02.2 a line of commas is a row with empty fields (DEC-05, DEC-06)' do
      subject(:run) { run_scenario(files: { 'transfers.csv' => ",,\n" }) }

      it_behaves_like 'a completed run',
                      stdout: template_r(line: '  Line 1  rejected  "" -> ""  ""  invalid_account_number',
                                         reason: 'invalid_account_number'),
                      stderr: <<~STDERR
                        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** "" invalid_account_number
                        W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
                      STDERR
    end

    describe 'AC-02.3 a header row is rejected with a hint; every row rejected still completes (DEC-06, DEC-21)' do
      subject(:run) { run_scenario(files: { 'transfers.csv' => "from,to,amount\n" }) }

      it_behaves_like 'a completed run',
                      output_file: "1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n",
                      stdout: <<~STDOUT, stderr: <<~STDERR
                        Transfers
                          Line 1  rejected  from -> to  amount  invalid_account_number: This looks like a header row; files must not have a header.

                        Summary
                          Processed: 1
                          Applied: 0
                          Rejected: 1
                            invalid_account_number: 1
                          Total before: 150.00
                          Total after: 150.00

                        Warning: All transfers were rejected; check this is the right file.

                        Final balances
                          1111234522226789  100.00
                          1212343433335665  50.00
                          0000123412341234  0.00

                        Output file: output/final_balances_2026-11-07_143005.csv
                      STDOUT
                        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** amount invalid_account_number
                        W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
                      STDERR
    end

    describe 'AC-02.3 from,to is malformed_row with the header hint (DEC-06, DEC-21)' do
      subject(:run) { run_scenario(files: { 'transfers.csv' => "from,to\n" }) }

      it_behaves_like 'a completed run',
                      stdout: template_r(line: '  Line 1  rejected  malformed_row: 2 fields, expected 3. ' \
                                               'This looks like a header row; files must not have a header.',
                                         reason: 'malformed_row'),
                      stderr: <<~STDERR
                        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** malformed_row
                        W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
                      STDERR
    end

    describe 'AC-02.4 an empty transfers file stops the run (DEC-20)' do
      subject(:run) do
        run_scenario(files: { 'empty.csv' => '' },
                     arguments: %w[balances.csv empty.csv output/final_balances_2026-11-07_143005.csv])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the transfers file has no transfers: empty.csv
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: transfers file has no transfers
      STDERR
    end

    describe 'AC-02.4 a transfers file of only blank lines stops the run (DEC-05, DEC-20)' do
      subject(:run) do
        run_scenario(files: { 'empty.csv' => "\n   \n\t\n" },
                     arguments: %w[balances.csv empty.csv output/final_balances_2026-11-07_143005.csv])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the transfers file has no transfers: empty.csv
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: transfers file has no transfers
      STDERR
    end

    describe 'AC-02.5 a transfers file that cannot be read past a line stops the run (DEC-04)' do
      subject(:run) do
        run_scenario(files: { 'bad.csv' => "1111234522226789,1212343433335665,10.00\n1111234522226789,\"10.00\n" },
                     arguments: %w[balances.csv bad.csv output/final_balances_2026-11-07_143005.csv])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: cannot read bad.csv from line 2. Check for an unclosed quote or characters that are not text.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
      STDERR
    end

    describe 'AC-02.5 a row rejected before the unreadable line is logged first (DEC-04, DEC-28)' do
      subject(:run) do
        run_scenario(files: { 'bad.csv' => "1111234522226789,1212343433335665,100.01\n1111234522226789,\"10.00\n" },
                     arguments: %w[balances.csv bad.csv output/final_balances_2026-11-07_143005.csv])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds
        Error: cannot read bad.csv from line 2. Check for an unclosed quote or characters that are not text.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
      STDERR
    end
  end

  describe 'FR-07 The order transfers are applied in' do
    describe 'AC-07.1 one pass, no retry, repeats applied (DEC-15, DEC-16)' do
      subject(:run) do
        run_scenario(files: { 'transfers.csv' => "0000123412341234,1212343433335665,20.00\n" \
                                                 "1111234522226789,0000123412341234,20.00\n" \
                                                 "1111234522226789,0000123412341234,20.00\n" })
      end

      it_behaves_like 'a completed run', stdout: <<~STDOUT, stderr: <<~STDERR
        Transfers
          Line 1  rejected  0000123412341234 -> 1212343433335665  20.00  insufficient_funds
          Line 2  applied  1111234522226789 -> 0000123412341234  20.00
          Line 3  applied  1111234522226789 -> 0000123412341234  20.00

        Summary
          Processed: 3
          Applied: 2
          Rejected: 1
            insufficient_funds: 1
          Total before: 150.00
          Total after: 150.00

        Final balances
          1111234522226789  60.00
          1212343433335665  50.00
          0000123412341234  40.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
        W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************5665 20.00 insufficient_funds
      STDERR
    end
  end

  describe 'FR-08 The end-of-day result and its output' do
    describe 'AC-08.1 the sample files give the exact expected result' do
      subject(:run) do
        run_scenario(files: sample_files,
                     arguments: %w[data/mable_account_balances.csv data/mable_transactions.csv
                                   output/final_balances_2026-11-07_143005.csv])
      end

      let(:sample_files) do
        %w[mable_account_balances.csv mable_transactions.csv].to_h do |name|
          ["data/#{name}", File.binread(fixture_path('sample', name))]
        end
      end

      it_behaves_like 'a completed run', stdout: sample_report, output_file: sample_output_file
    end
  end

  describe 'FR-09 The runner' do
    let(:given) { {} }
    let(:paths) { run.then { given[:paths] } }
    let(:files) { { 'b.csv' => "1111234522226789,100.00\n", 't.csv' => "1111234522226789,1212343433335665,10.00\n" } }
    let(:project_output) { Dir.glob(File.join(Runs::PROJECT_ROOT, 'output', '*')) }

    before do
      day = instance_double(ProcessDailyTransfer, call: nil)
      allow(day).to receive(:call) { |*called_with| given[:paths] = called_with }
      allow(ProcessDailyTransfer).to receive(:new) { |**parts| given.store(:parts, parts) && day }
    end

    def in_project(path)
      File.expand_path(path, Runs::PROJECT_ROOT)
    end

    def in_temp(path)
      File.expand_path(path, run.temp_folder)
    end

    def default_output
      in_project(FinalBalancesCsvWriter.default_path(given[:parts][:run_time]))
    end

    describe 'AC-09.1 no arguments' do
      subject(:run) { run_scenario(files: files, arguments: []) }

      it 'reads the sample balances file in the project data folder (DEC-22)' do
        expect(in_temp(paths[0])).to eq(in_project('data/mable_account_balances.csv'))
      end

      it 'reads the sample transfers file in the project data folder (DEC-22)' do
        expect(in_temp(paths[1])).to eq(in_project('data/mable_transactions.csv'))
      end

      it 'writes to the default output path under the project root, named from the run time (DEC-27)' do
        expect(in_temp(paths[2])).to eq(default_output)
      end

      it 'gives the input files in full, as they are outside the current folder (DEC-26)' do
        expect(paths.first(2)).to eq([in_project('data/mable_account_balances.csv'),
                                      in_project('data/mable_transactions.csv')])
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end

      it "writes nothing in the project's output folder (DEC-27)" do
        expect { run }.not_to(change { project_output })
      end
    end

    describe 'AC-09.1 b.csv t.csv' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv]) }

      it 'reads b.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[0])).to eq(File.join(run.temp_folder, 'b.csv'))
      end

      it 'reads t.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[1])).to eq(File.join(run.temp_folder, 't.csv'))
      end

      it 'writes to the default output path under the project root (DEC-27)' do
        expect(in_temp(paths[2])).to eq(default_output)
      end

      it 'gives the input paths in their shown form (DEC-26)' do
        expect(paths.first(2)).to eq(%w[b.csv t.csv])
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end

      it "writes nothing in the project's output folder (DEC-27)" do
        expect { run }.not_to(change { project_output })
      end
    end

    describe 'AC-09.1 b.csv t.csv out/day1.csv' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv out/day1.csv]) }

      it 'writes to out/day1.csv in the current folder (DEC-22)' do
        expect(in_temp(paths[2])).to eq(File.join(run.temp_folder, 'out/day1.csv'))
      end

      it 'gives the output path in full' do
        expect(paths[2]).to eq(File.join(run.temp_folder, 'out/day1.csv'))
      end

      it 'returns 0' do
        expect(run.status).to eq(0)
      end
    end

    describe 'the parts given to ProcessDailyTransfer (DEC-30)' do
      subject(:run) { run_scenario(files: files, arguments: %w[b.csv t.csv]) }

      let(:parts) { run.then { given[:parts] } }

      it 'gives a run time that is a Time' do
        expect(parts[:run_time]).to be_a(Time)
      end

      it 'gives exactly the six parts and the run time' do
        expect(parts.keys).to contain_exactly(:run_time, :balances_reader, :transfers_reader, :writer, :repository,
                                              :reporter, :logger)
      end

      it 'gives the real readers, writer, repository, reporter and logger' do
        expect(parts.except(:run_time).transform_values(&:class)).to eq(
          balances_reader: BalancesCsvReader, transfers_reader: TransfersCsvReader, writer: FinalBalancesCsvWriter,
          repository: AccountRepository, reporter: ReportPrinter, logger: Logger
        )
      end
    end
  end
end
