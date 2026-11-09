# frozen_string_literal: true

require 'infrastructure/runner'
require 'application/errors'
require 'application/process_daily_transfer'
require 'domain/account_repository'
require 'domain/money'
require 'infrastructure/balances_csv_reader'
require 'infrastructure/final_balances_csv_writer'
require 'infrastructure/report_printer'
require 'infrastructure/transfers_csv_reader'

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
          Account           Opening  Closing
          1111234522226789   100.00    95.00
          1212343433335665    50.00    55.00
          0000123412341234     0.00     0.00

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
                          Account           Opening  Closing
                          1111234522226789   100.00   100.00
                          1212343433335665    50.00    50.00
                          0000123412341234     0.00     0.00

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

  describe 'FR-03 to FR-06 (owned by 001)' do
    # Each row is line 1 of transfers.csv. An applied row gives Template A with its transfer and final balances;
    # a rejected row gives Template R with its report line, and its warn line ends with the reason code.
    invalid_amounts = ['0', '0.00', '-5.00', '-0', '-0.00', '1.234', 'abc', '10.', '.50', '+10', '1e3', '$10', '1 0']
    domain_rows = [
      { name: 'AC-03.1 1111234522226789,1212343433335665,30.00', row: '1111234522226789,1212343433335665,30.00',
        transfer: '1111234522226789 -> 1212343433335665  30.00', balances: %w[70.00 80.00 0.00] },
      { name: 'AC-03.3 12345,1212343433335665,abc', row: '12345,1212343433335665,abc',
        report: '12345 -> 1212343433335665  abc  invalid_account_number',
        warn: '*2345 -> ************5665 abc invalid_account_number' },
      { name: 'AC-03.3 1111234522226789,1111234522226789,0', row: '1111234522226789,1111234522226789,0',
        report: '1111234522226789 -> 1111234522226789  0  invalid_amount',
        warn: '************6789 -> ************6789 0 invalid_amount' },
      { name: 'AC-03.3 9999888877776666,9999888877776666,5.00', row: '9999888877776666,9999888877776666,5.00',
        report: '9999888877776666 -> 9999888877776666  5.00  same_account',
        warn: '************6666 -> ************6666 5.00 same_account' },
      { name: 'AC-04.1 100.01 is more than the balance', row: '1111234522226789,1212343433335665,100.01',
        report: '1111234522226789 -> 1212343433335665  100.01  insufficient_funds',
        warn: '************6789 -> ************5665 100.01 insufficient_funds' },
      { name: 'AC-04.2 100.00 leaves exactly 0.00 (DEC-13)', row: '1111234522226789,1212343433335665,100.00',
        transfer: '1111234522226789 -> 1212343433335665  100.00', balances: %w[0.00 150.00 0.00] },
      { name: 'AC-04.3 0.01 from the 0.00 account', row: '0000123412341234,1111234522226789,0.01',
        report: '0000123412341234 -> 1111234522226789  0.01  insufficient_funds',
        warn: '************1234 -> ************6789 0.01 insufficient_funds' },
      { name: 'AC-05.1 an unknown to account (DEC-17)', row: '1111234522226789,9999888877776666,10.00',
        report: '1111234522226789 -> 9999888877776666  10.00  unknown_account',
        warn: '************6789 -> ************6666 10.00 unknown_account' },
      { name: 'AC-05.2 an unknown from account (DEC-17)', row: '9999888877776666,1111234522226789,10.00',
        report: '9999888877776666 -> 1111234522226789  10.00  unknown_account',
        warn: '************6666 -> ************6789 10.00 unknown_account' },
      { name: 'AC-06.1 from 1111234522226789', row: '1111234522226789,1212343433335665,10.00',
        transfer: '1111234522226789 -> 1212343433335665  10.00', balances: %w[90.00 60.00 0.00] },
      { name: 'AC-06.1 from 0000123412341234 matches the leading zeros (DEC-08)',
        row: '0000123412341234,1212343433335665,10.00',
        report: '0000123412341234 -> 1212343433335665  10.00  insufficient_funds',
        warn: '************1234 -> ************5665 10.00 insufficient_funds' },
      { name: 'AC-06.1 from 111123452222678 (DEC-08, DEC-29)', row: '111123452222678,1212343433335665,10.00',
        report: '111123452222678 -> 1212343433335665  10.00  invalid_account_number',
        warn: '***********2678 -> ************5665 10.00 invalid_account_number' },
      { name: 'AC-06.1 from 11112345222267890 (DEC-08, DEC-29)', row: '11112345222267890,1212343433335665,10.00',
        report: '11112345222267890 -> 1212343433335665  10.00  invalid_account_number',
        warn: '*************7890 -> ************5665 10.00 invalid_account_number' },
      { name: 'AC-06.1 from 1111O34522226789 (DEC-08, DEC-29)', row: '1111O34522226789,1212343433335665,10.00',
        report: '1111O34522226789 -> 1212343433335665  10.00  invalid_account_number',
        warn: '************6789 -> ************5665 10.00 invalid_account_number' },
      { name: 'AC-06.1 from 1111-2345-2222-6789 (DEC-08, DEC-29)', row: '1111-2345-2222-6789,1212343433335665,10.00',
        report: '1111-2345-2222-6789 -> 1212343433335665  10.00  invalid_account_number',
        warn: '***************6789 -> ************5665 10.00 invalid_account_number' },
      { name: 'AC-06.2 amount 10', row: '1111234522226789,1212343433335665,10',
        transfer: '1111234522226789 -> 1212343433335665  10.00', balances: %w[90.00 60.00 0.00] },
      { name: 'AC-06.2 amount 10.5', row: '1111234522226789,1212343433335665,10.5',
        transfer: '1111234522226789 -> 1212343433335665  10.50', balances: %w[89.50 60.50 0.00] },
      { name: 'AC-06.2 amount 10.50', row: '1111234522226789,1212343433335665,10.50',
        transfer: '1111234522226789 -> 1212343433335665  10.50', balances: %w[89.50 60.50 0.00] },
      { name: 'AC-06.2 amount 007.50', row: '1111234522226789,1212343433335665,007.50',
        transfer: '1111234522226789 -> 1212343433335665  7.50', balances: %w[92.50 57.50 0.00] },
      *invalid_amounts.map do |amount|
        { name: "AC-06.2 amount #{amount} (DEC-09, DEC-10)", row: "1111234522226789,1212343433335665,#{amount}",
          report: "1111234522226789 -> 1212343433335665  #{amount}  invalid_amount",
          warn: "************6789 -> ************5665 #{amount} invalid_amount" }
      end,
      { name: 'AC-06.2 an empty amount (DEC-09)', row: '1111234522226789,1212343433335665,',
        report: '1111234522226789 -> 1212343433335665  ""  invalid_amount',
        warn: '************6789 -> ************5665 "" invalid_amount' },
      { name: 'AC-06.2 amount "1,000.00" quoted (DEC-09)', row: '1111234522226789,1212343433335665,"1,000.00"',
        report: '1111234522226789 -> 1212343433335665  1,000.00  invalid_amount',
        warn: '************6789 -> ************5665 1,000.00 invalid_amount' },
      { name: 'AC-06.2 amount 1,000.00 not quoted is 4 fields (DEC-09)',
        row: '1111234522226789,1212343433335665,1,000.00', report: 'malformed_row: 4 fields, expected 3',
        warn: '************6789 -> ************5665 1 malformed_row' }
    ]

    domain_rows.each do |scenario|
      describe scenario[:name] do
        subject(:run) { run_scenario(files: { 'transfers.csv' => "#{scenario[:row]}\n" }) }

        if scenario[:balances]
          it_behaves_like 'a completed run',
                          stdout: template_a(transfer: scenario[:transfer], balances: scenario[:balances])
        else
          it_behaves_like 'a completed run',
                          stdout: template_r(line: "  Line 1  rejected  #{scenario[:report]}",
                                             reason: scenario[:warn].split.last),
                          stderr: "W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: #{scenario[:warn]}\n" \
                                  'W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; ' \
                                  "check this is the right file.\n"
        end
      end
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
          Account           Opening  Closing
          1111234522226789   100.00    60.00
          1212343433335665    50.00    50.00
          0000123412341234     0.00    40.00

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

      it_behaves_like 'a completed run', stdout: sample_report, output_file: sample_output_file
    end

    describe 'AC-08.2 a day with mixed rejections' do
      subject(:run) do
        run_scenario(files: { 'transfers.csv' => "1111234522226789,1212343433335665,30.00\n" \
                                                 "1111234522226789,1212343433335665,90.00\n" \
                                                 "1212343433335665,9999888877776666,10.00\n" \
                                                 "1111234522226789,0000123412341234,70.00\n" \
                                                 "1212343433335665,1212343433335665,5.00\n" })
      end

      it_behaves_like 'a completed run', stdout: <<~STDOUT, stderr: <<~STDERR, output_file: <<~OUTPUT
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
          Account           Opening  Closing
          1111234522226789   100.00     0.00
          1212343433335665    50.00    80.00
          0000123412341234     0.00    70.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
        W, [<timestamp> #<pid>]  WARN -- : Line 2 rejected: ************6789 -> ************5665 90.00 insufficient_funds
        W, [<timestamp> #<pid>]  WARN -- : Line 3 rejected: ************5665 -> ************6666 10.00 unknown_account
        W, [<timestamp> #<pid>]  WARN -- : Line 5 rejected: ************5665 -> ************5665 5.00 same_account
      STDERR
        1111234522226789,0.00
        1212343433335665,80.00
        0000123412341234,70.00
      OUTPUT
    end

    describe 'AC-08.3 the output file fed back in as the balances file (DEC-27)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1111234522226789,0.00\n1212343433335665,80.00\n" \
                                                "0000123412341234,70.00\n",
                              'transfers.csv' => "1212343433335665,1111234522226789,10.00\n" })
      end

      it_behaves_like 'a completed run',
                      stdout: template_a(transfer: '1212343433335665 -> 1111234522226789  10.00',
                                         balances: %w[10.00 70.00 70.00], openings: %w[0.00 80.00 70.00])
    end

    describe 'AC-08.3 a third argument with missing folders (DEC-27)' do
      subject(:run) do
        run_scenario(arguments: %w[balances.csv transfers.csv out/new/day1.csv], read: ['out/new/day1.csv'])
      end

      it_behaves_like 'a completed run',
                      stdout: template_a(transfer: '1111234522226789 -> 1212343433335665  10.00',
                                         balances: %w[90.00 60.00 0.00], output_file: 'out/new/day1.csv')

      it 'creates the missing folders and the output file' do
        expect(run.files['out/new/day1.csv']).not_to be_nil
      end
    end

    describe 'AC-08.4 run from a subfolder, the output file outside it (DEC-26)' do
      subject(:run) do
        run_scenario(folder: 'docs',
                     arguments: %w[../balances.csv ../transfers.csv ../output/final_balances_2026-11-07_143005.csv])
      end

      it 'shows the output path in full on standard output' do
        expect(run.stdout).to eq(template_a(transfer: '1111234522226789 -> 1212343433335665  10.00',
                                            balances: %w[90.00 60.00 0.00],
                                            output_file: File.join(run.temp_folder, Runs::OUTPUT_FILE)))
      end

      it 'writes nothing on standard error' do
        expect(run.stderr).to eq('')
      end

      it 'exits with status 0 (AC-09.8)' do
        expect(run.status).to eq(0)
      end

      it 'writes the output file' do
        expect(run.output_file).to eq("1111234522226789,90.00\n1212343433335665,60.00\n0000123412341234,0.00\n")
      end
    end

    describe 'AC-08.4 an output file in another folder (DEC-26, P10)' do
      subject(:run) do
        run_scenario(folder: 'docs', arguments: ['../balances.csv', '../transfers.csv', other_output])
      end

      let(:other_folder) { Dir.mktmpdir }
      let(:other_output) { File.join(File.expand_path(other_folder), 'day1.csv') }

      after { FileUtils.remove_entry(other_folder) }

      it 'shows the output path in full on standard output' do
        expect(run.stdout).to eq(template_a(transfer: '1111234522226789 -> 1212343433335665  10.00',
                                            balances: %w[90.00 60.00 0.00], output_file: other_output))
      end

      it 'writes nothing on standard error' do
        expect(run.stderr).to eq('')
      end

      it 'exits with status 0 (AC-09.8)' do
        expect(run.status).to eq(0)
      end
    end

    describe 'AC-08.5 a changed total stops the run (DEC-24)' do
      subject(:run) { run_scenario }

      before do
        day = instance_double(ProcessDailyTransfer)
        allow(day).to receive(:call).and_raise(TotalChanged.new(Money.amount('66750.00'), Money.amount('66749.00')))
        allow(ProcessDailyTransfer).to receive(:new).and_return(day)
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: the total of all balances changed from 66750.00 to 66749.00. No output file was written.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: total of all balances changed
      STDERR
    end

    describe 'AC-09.4 an output path that is an existing folder (DEC-25)' do
      subject(:run) do
        run_scenario(files: { 'out' => :folder }, arguments: %w[balances.csv transfers.csv out], read: ['out', 'out/'])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: cannot write output file out: <reason from the system>
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot write output file
      STDERR

      it 'leaves the folder in place' do
        expect(run.files['out']).to eq(:folder)
      end

      it 'leaves the folder empty' do
        expect(run.files['out/']).to eq([])
      end
    end
  end

  describe 'FR-09 The runner' do
    let(:given) { {} }
    let(:paths) { run.then { given[:paths] } }
    let(:files) { { 'b.csv' => "1111234522226789,100.00\n", 't.csv' => "1111234522226789,1212343433335665,10.00\n" } }
    let(:project_output) { Dir.glob(File.join(Runs::PROJECT_ROOT, 'output', '*')) }

    shared_context 'with a stand-in ProcessDailyTransfer' do
      before do
        day = instance_double(ProcessDailyTransfer, call: nil)
        allow(day).to receive(:call) { |*called_with| given[:paths] = called_with }
        allow(ProcessDailyTransfer).to receive(:new) do |parts, run_time:|
          given.update(parts: parts, run_time: run_time) && day
        end
      end
    end

    def sample_run(env: {}, output: Runs::OUTPUT_FILE)
      run_scenario(files: sample_files, env: env, read: [output],
                   arguments: ['data/mable_account_balances.csv', 'data/mable_transactions.csv', output])
    end

    def in_project(path)
      File.expand_path(path, Runs::PROJECT_ROOT)
    end

    def in_temp(path)
      File.expand_path(path, run.temp_folder)
    end

    def default_output
      in_project(FinalBalancesCsvWriter.default_path(given[:run_time]))
    end

    describe 'AC-09.1 no arguments' do
      subject(:run) { run_scenario(files: files, arguments: []) }

      include_context 'with a stand-in ProcessDailyTransfer'

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

      include_context 'with a stand-in ProcessDailyTransfer'

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

      include_context 'with a stand-in ProcessDailyTransfer'

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

      include_context 'with a stand-in ProcessDailyTransfer'

      it 'gives a run time that is a Time' do
        expect(run.then { given[:run_time] }).to be_a(Time)
      end

      it 'gives the parts as one ProcessDailyTransfer::Parts' do
        expect(parts).to be_a(ProcessDailyTransfer::Parts)
      end

      it 'gives the real readers, writer, repository, reporter and logger' do
        expect(parts.to_h.transform_values(&:class)).to eq(
          balances_reader: BalancesCsvReader, transfers_reader: TransfersCsvReader, writer: FinalBalancesCsvWriter,
          repository: AccountRepository, reporter: ReportPrinter, logger: Logger
        )
      end
    end

    [%w[balances.csv], %w[a b c d], %w[-h], %w[--help]].each do |arguments|
      describe "AC-09.2 #{arguments.join(' ')}" do
        subject(:run) { run_scenario(arguments: arguments, read: ['output/']) }

        it 'prints nothing on standard output' do
          expect(run.stdout).to eq('')
        end

        it 'writes exactly the two usage lines on standard error, with no log line (DEC-22)' do
          expect(run.stderr).to eq("Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]\n" \
                                   "With no arguments, runs the sample files in data/.\n")
        end

        it 'exits with status 1 (AC-09.8)' do
          expect(run.status).to eq(1)
        end

        it 'creates no output folder (DEC-22)' do
          expect(run.files['output/']).to be_nil
        end
      end
    end

    describe 'AC-09.3 two missing files and an existing output file are reported together (DEC-23, DEC-25)' do
      subject(:run) do
        run_scenario(files: { 'out/day1.csv' => 'old' }, arguments: %w[missing1.csv missing2.csv out/day1.csv],
                     read: ['out/day1.csv'])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: file not found: missing1.csv
        Error: file not found: missing2.csv
        Error: output file already exists: out/day1.csv. Delete it or give another output path.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found, output file already exists)
      STDERR

      it 'leaves out/day1.csv unchanged (DEC-25)' do
        expect(run.files['out/day1.csv']).to eq('old')
      end
    end

    describe 'AC-09.3 only the two missing files (DEC-23)' do
      subject(:run) { run_scenario(arguments: %w[missing1.csv missing2.csv]) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: file not found: missing1.csv
        Error: file not found: missing2.csv
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found)
      STDERR
    end

    describe 'AC-09.3 only an existing output file (DEC-25)' do
      subject(:run) do
        run_scenario(files: { 'out/day1.csv' => 'old' }, arguments: %w[balances.csv transfers.csv out/day1.csv],
                     read: ['out/day1.csv'])
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: output file already exists: out/day1.csv. Delete it or give another output path.
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)
      STDERR

      it 'leaves the bytes of out/day1.csv unchanged (DEC-25)' do
        expect(run.files['out/day1.csv']).to eq('old')
      end
    end

    describe 'AC-09.3a a folder named balances.csv cannot be opened (DEC-23)' do
      subject(:run) { run_scenario(files: { 'balances.csv' => :folder }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: cannot read file balances.csv: <reason from the system>
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
      STDERR
    end

    describe 'AC-09.3a a folder named transfers.csv cannot be opened (DEC-23)' do
      subject(:run) { run_scenario(files: { 'transfers.csv' => :folder }) }

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        Error: cannot read file transfers.csv: <reason from the system>
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
      STDERR
    end

    %w[info INFO Info].each do |level|
      describe "AC-09.5 LOG_LEVEL=#{level}" do
        subject(:run) { sample_run(env: { 'LOG_LEVEL' => level }) }

        it_behaves_like 'a completed run', stdout: sample_report, stderr: <<~STDERR
          I, [<timestamp> #<pid>]  INFO -- : Run started: balances data/mable_account_balances.csv, transfers data/mable_transactions.csv
          I, [<timestamp> #<pid>]  INFO -- : Line 1 applied: ************6789 -> ************5665 500.00
          I, [<timestamp> #<pid>]  INFO -- : Line 2 applied: ************5755 -> ************1212 1000.00
          I, [<timestamp> #<pid>]  INFO -- : Line 3 applied: ************5755 -> ************6789 320.50
          I, [<timestamp> #<pid>]  INFO -- : Line 4 applied: ************1234 -> ************5665 25.60
          I, [<timestamp> #<pid>]  INFO -- : Run ended: processed 4, applied 4, rejected 0
        STDERR
      end
    end

    [nil, 'warn', 'debug', ' info '].each do |level|
      describe "AC-09.5 #{level ? "LOG_LEVEL=#{level.inspect}" : 'LOG_LEVEL unset'} is the warn level (DEC-28)" do
        subject(:run) { sample_run(env: { 'LOG_LEVEL' => level }.compact) }

        it_behaves_like 'a completed run', stdout: sample_report
      end
    end

    describe 'AC-09.5 LOG_LEVEL=info on a stopped run logs Run started but no Run ended (DEC-28)' do
      subject(:run) do
        run_scenario(files: { 'balances.csv' => "1111234522226789,5000.00\n\n12345,100.00\n1212343433335665,abc,9\n" \
                                                "1111234522226789,10.00\n2222123433331212,-5.00\n" \
                                                "3212343433335755,1.234\n" },
                     env: { 'LOG_LEVEL' => 'info' })
      end

      it_behaves_like 'a stopped run', stderr: <<~STDERR
        I, [<timestamp> #<pid>]  INFO -- : Run started: balances balances.csv, transfers transfers.csv
        Error: the balances file is invalid (5 problems):
          Line 3: account number "12345" must be exactly 16 digits
          Line 4: expected 2 fields, found 3
          Line 5: account 1111234522226789 appears more than once (first on line 1)
          Line 6: balance "-5.00" must not be negative
          Line 7: balance "1.234" has more than 2 decimal places
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 5 problems
      STDERR
    end

    describe 'AC-09.5 LOG_LEVEL=info with rejections (DEC-28)' do
      subject(:run) do
        run_scenario(files: { 'transfers.csv' => "1111234522226789,1212343433335665,30.00\n" \
                                                 "1111234522226789,1212343433335665,90.00\n" \
                                                 "1212343433335665,9999888877776666,10.00\n" \
                                                 "1111234522226789,0000123412341234,70.00\n" \
                                                 "1212343433335665,1212343433335665,5.00\n" },
                     env: { 'LOG_LEVEL' => 'info' })
      end

      it_behaves_like 'a completed run', stdout: <<~STDOUT, stderr: <<~STDERR
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
          Account           Opening  Closing
          1111234522226789   100.00     0.00
          1212343433335665    50.00    80.00
          0000123412341234     0.00    70.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
        I, [<timestamp> #<pid>]  INFO -- : Run started: balances balances.csv, transfers transfers.csv
        I, [<timestamp> #<pid>]  INFO -- : Line 1 applied: ************6789 -> ************5665 30.00
        W, [<timestamp> #<pid>]  WARN -- : Line 2 rejected: ************6789 -> ************5665 90.00 insufficient_funds
        W, [<timestamp> #<pid>]  WARN -- : Line 3 rejected: ************5665 -> ************6666 10.00 unknown_account
        I, [<timestamp> #<pid>]  INFO -- : Line 4 applied: ************6789 -> ************1234 70.00
        W, [<timestamp> #<pid>]  WARN -- : Line 5 rejected: ************5665 -> ************5665 5.00 same_account
        I, [<timestamp> #<pid>]  INFO -- : Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)
      STDERR
    end

    describe 'AC-09.6 LOG_LEVEL=info on the sample files masks account numbers only in log lines (DEC-29)' do
      subject(:run) { sample_run(env: { 'LOG_LEVEL' => 'info' }) }

      it 'shows 1111234522226789 in full in the report' do
        expect(run.stdout).to include('1111234522226789')
      end

      it 'shows no run of 16 digits in any log line' do
        expect(run.stderr).not_to match(/\d{16}/)
      end
    end

    describe 'AC-09.7 the first of two runs on the sample files (DEC-03)' do
      subject(:run) { sample_run(output: 'output/final_balances_2026-11-07_143005.csv') }

      it_behaves_like 'a completed run', stdout: sample_report
    end

    describe 'AC-09.7 the second of two runs on the sample files (DEC-03)' do
      subject(:run) { sample_run(output: 'output/final_balances_2026-11-07_143006.csv') }

      it_behaves_like 'a completed run',
                      stdout: sample_report(output_file: 'output/final_balances_2026-11-07_143006.csv')
    end

    describe 'AC-09.7 two runs on the sample files give the same result (DEC-02, DEC-03)' do
      subject(:runs) do
        %w[output/final_balances_2026-11-07_143005.csv output/final_balances_2026-11-07_143006.csv].map do |output|
          sample_run(output: output)
        end
      end

      it 'prints the same report apart from the Output file line' do
        expect(runs.map { |each_run| each_run.stdout.lines[0...-1] }.uniq.size).to eq(1)
      end

      it 'writes output files with the same bytes' do
        expect(runs.map { |each_run| each_run.files.values.first }.uniq.size).to eq(1)
      end

      it 'writes each output file' do
        expect(runs.map { |each_run| each_run.files.values.first }).to all(be_a(String))
      end
    end

    describe 'leading zeros are matched across both files (DEC-08)' do
      subject(:run) do
        run_scenario(files: %w[balances.csv transfers.csv].to_h { |name| [name, read_fixture(name)] })
      end

      def read_fixture(name)
        File.binread(fixture_path('leading_zeros', name))
      end

      it_behaves_like 'a completed run', stdout: <<~STDOUT
        Transfers
          Line 1  applied  0000123412341234 -> 1111234522226789  10.00

        Summary
          Processed: 1
          Applied: 1
          Rejected: 0
          Total before: 150.00
          Total after: 150.00

        Final balances
          Account           Opening  Closing
          0000123412341234    50.00    40.00
          1111234522226789   100.00   110.00

        Output file: output/final_balances_2026-11-07_143005.csv
      STDOUT
    end

    describe 'an unexpected error is not caught (page 10 pick 45)' do
      before do
        day = instance_double(ProcessDailyTransfer)
        allow(day).to receive(:call).and_raise(RuntimeError, 'an unexpected bug')
        allow(ProcessDailyTransfer).to receive(:new).and_return(day)
      end

      it 'lets the RuntimeError reach the caller' do
        expect { run_scenario }.to raise_error(RuntimeError, 'an unexpected bug')
      end
    end
  end
end
