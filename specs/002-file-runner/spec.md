# Feature Specification: File reading, the day's run and the runner

**Feature Branch**: `002-file-runner`

**Created**: 2026-11-07

**Status**: Draft

**Input**: User description: "Spec 002-file-runner, short name "file-runner": the second of the three specs in the Spec Kit brief. Owns FR-01, FR-02, FR-07, FR-08, FR-09, NFR-03 and NFR-06, and builds the application layer, the infrastructure layer and bin/run on the finished 001-domain." The full input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#002-file-runner).

## Sources and ownership

- **Sources, in order of precedence**: [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) (DEC-01 to DEC-38, the source of truth); the solution design pages [02](../../docs/solution-design/02-functional-requirements.md) (FR-01, FR-02, FR-07 to FR-09, and every scenario for the runner tests), [03](../../docs/solution-design/03-non-functional-requirements.md), [05](../../docs/solution-design/05-high-level-design.md), [06](../../docs/solution-design/06-components.md), [07](../../docs/solution-design/07-logical-flow/README.md) (all pages), [08.3](../../docs/solution-design/08-alternatives/03-errors-and-rejected-transfers.md) to [08.6](../../docs/solution-design/08-alternatives/06-logging.md), [09](../../docs/solution-design/09-considerations.md) and [10](../../docs/solution-design/10-traceability-glossary-assumptions.md); then `CLAUDE.md` and the [constitution](../../.specify/memory/constitution.md). If this spec ever differs from them, they win.
- **Builds on**: [`001-domain`](../001-domain/spec.md). Every domain class, member, error and message is used exactly as `001` and [page 6](../../docs/solution-design/06-components.md) name it: `AccountNumber`, `Money`, `Account` (`withdraw`, `deposit`, the class-level opening-balance check), `Transfer`, `TransferResult`, `AccountRepository` (`add`, `include?`, `find`, `all`), `TransferService`, and the errors `InvalidAccountNumber`, `InvalidAmount`, `SameAccount`, `NegativeBalance`, `UnknownAccount`, `DuplicateAccount`, `InsufficientFunds`. This spec adds no domain rule and never rewrites a domain message.
- **This spec owns**: FR-01 Load the balances file, FR-02 Read the transfers file, FR-07 The order transfers are applied in, FR-08 The end-of-day result and its output, FR-09 The runner, NFR-03 Scale, NFR-06 Testability and coverage. It owns no other FR or NFR.
- **Run here but owned by `001-domain`**: the page 2 scenarios of FR-03, FR-04, FR-05 and FR-06 (AC-03.1 to AC-06.3). This spec runs each of them through the runner with real CSV files and checks the exact standard output, standard error and exit status ([User Story 6](#user-story-6---every-domain-scenario-gives-its-exact-run-outcome-priority-p2)); `001` owns the rules and their domain unit tests.
- **Built in `001`, used here**: the project skeleton (RSpec with random order and documentation format, SimpleCov, RuboCop with `rubocop-rspec`, `.gitignore`). NFR-05 is owned by `001`; this spec keeps RuboCop at zero offences. The README, CI and Docker are `003-delivery`.

### Conventions used in the scenarios

These are copied from [page 2](../../docs/solution-design/02-functional-requirements.md#how-to-read-the-acceptance-criteria):

- **Standard output** (stdout) carries the report only. **Standard error** (stderr) carries error messages and log lines. "(nothing)" means the stream stays empty.
- The **exit status** is 0 for a completed run and 1 for a stopped run ([DEC-25](../../docs/design-analysis/design-decisions.md#dec-25)).
- Every run starts at 2026-11-07 14:30:05 local time, from the project root, with the default log level (warn: only warnings and errors are logged) unless a scenario says otherwise. The default output file is then `output/final_balances_2026-11-07_143005.csv`.
- Log lines use Ruby's standard log format. `<timestamp>` stands for the date and time to the microsecond and `<pid>` for the process number, which change on every run.
- Every file path in a message or log line is shown the same way as the output path in the report: relative to the folder the command was run from, or in full if the file is outside it.
- Unless a scenario says otherwise, the command is `bin/run balances.csv transfers.csv`, and `balances.csv`, with a total of 150.00, is:

```
1111234522226789,100.00
1212343433335665,50.00
0000123412341234,0.00
```

- A single-row example uses the row as line 1 of `transfers.csv`, the only row (decided in the run, as in `001`).
- Unless a scenario says otherwise, `transfers.csv` holds the one row `1111234522226789,1212343433335665,10.00` (AC-01.1's file), so that the start checks pass and a scenario about the balances file or the arguments reads a transfers file that exists (decided in the run, item 23).
- **How the tests reproduce a page 2 run** (decided in the run, item 1): each runner scenario runs `Runner` with a temporary folder as the current folder, writes the scenario's CSV files into it under the names shown, and passes `output/final_balances_2026-11-07_143005.csv` as the third argument. The report, messages and log lines are then character for character those of `bin/run balances.csv transfers.csv` at the page 2 run time, without the test reading or stubbing the clock ([DEC-30](../../docs/design-analysis/design-decisions.md#dec-30)).

### Report templates (derived)

Lines marked **(derived)** in the scenarios are not printed in full on page 2 for that criterion; they are built from the report layout in [FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output), the masking rule in AC-09.6 and the all-rejected warning in [DEC-21](../../docs/design-analysis/design-decisions.md#dec-21), and they add no behaviour.

**Template A** (a single applied row of `transfers.csv` with `balances.csv`): standard output is exactly

```
Transfers
  Line 1  applied  <from> -> <to>  <amount>

Summary
  Processed: 1
  Applied: 1
  Rejected: 0
  Total before: 150.00
  Total after: 150.00

Final balances
  Account           Opening  Closing
  1111234522226789  <opening 1>  <balance 1>
  1212343433335665  <opening 2>  <balance 2>
  0000123412341234  <opening 3>  <balance 3>

Output file: output/final_balances_2026-11-07_143005.csv
```

where `<opening 1>` to `<opening 3>` are the balances file's balances (`100.00`, `50.00`, `0.00` for `balances.csv`) and `<balance 1>` to `<balance 3>` the closing balances. Every opening and closing balance in these scenarios is at most 7 characters, so each is right-aligned to the width of its heading, `Opening` or `Closing` (DEC-26).

**Template R** (a single rejected row of `transfers.csv` with `balances.csv`): standard output is exactly

```
Transfers
  <transfers line>

Summary
  Processed: 1
  Applied: 0
  Rejected: 1
    <reason code>: 1
  Total before: 150.00
  Total after: 150.00

Warning: All transfers were rejected; check this is the right file.

Final balances
  Account           Opening  Closing
  1111234522226789   100.00   100.00
  1212343433335665    50.00    50.00
  0000123412341234     0.00     0.00

Output file: output/final_balances_2026-11-07_143005.csv
```

and standard error is exactly the row's warn line followed by

```
W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
```

Template R is the layout page 2 prints in full in AC-02.3.

## Clarifications

### Session 2026-11-07

Answered from `design-decisions.md` and the solution design (no developer was asked; each answer is also an item in [Decided in the run](#decided-in-the-run)).

- Q: When a value in either file has tabs around it as well as spaces, are the tabs trimmed too? → A: Yes. Spaces and tabs around each value are trimmed (DEC-04), the same whitespace that makes a line blank (DEC-05); `1111234522226789,<tab>100.00` loads as `100.00`. Spaces or tabs inside a value are kept, so `1 0` stays invalid. (FR-001; item 18)
- Q: Does the duplicate known gap also cover a first copy rejected for a reason other than an invalid balance, such as the wrong number of fields or a negative balance? → A: Yes. Any first copy that is not added because of its own problem (the wrong number of fields, or an invalid or negative balance) leaves the later copy unseen as a duplicate; only the first row's problem is reported and the run stops either way (DEC-12; page 6 known gap). (FR-011, AC-01.10; item 19)
- Q: With `LOG_LEVEL=info`, which info lines appear in a run that passes the start checks and then stops? → A: `Run started: ...` is logged first, then any `Line <N> applied` and warn lines for the rows read before the stop, then the `Error:` line(s) and the error log line; `Run ended` is never logged for a stopped run. A run stopped by the arguments or the start checks logs no info line (DEC-28; FR-013 order). (FR-013, FR-020, AC-09.5; item 20)
- Q: If a missing folder on the output path cannot be created (for example a file stands where a folder should be, or permission is denied), what happens? → A: The run stops with `OutputNotWritable` and the message `cannot write output file <path>: <reason from the system>`, exactly as in AC-09.4; folders already created on the way are left in place, because no output file is left behind (DEC-25, DEC-27). (FR-026; item 21)
- Q: How do the end-to-end specs compare standard output and standard error when `bin/run` runs on Windows, where Ruby writes a line ending as CR LF to a pipe? → A: They turn each CR LF into LF in the captured standard output and standard error before comparing them exactly; the output file is compared byte for byte and must use LF only (page 2 pick 17). The program itself is not changed for this (DEC-26, DEC-34, NFR-04). (FR-044; item 22)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The sample files give the exact expected result (Priority: P1)

A reviewer runs the challenge's two sample files with `bin/run` and no arguments, and gets the exact report on standard output, the exact final balances file and exit status 0 ([FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output), [FR-09](../../docs/solution-design/02-functional-requirements.md#fr-09-the-runner); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).

**Why this priority**: the rubric checks that the program "runs and provides feedback" and "calculates the test files accurately"; this is the first thing a reviewer does.

**Independent Test**: the sample-files end-to-end run: `bin/run` as a separate process on copies of the two sample files, comparing standard output, standard error, the output file and the exit status.

**Acceptance Scenarios**:

1. **AC-08.1 The sample files give the exact expected result** (FR-08, NFR-01; DEC-22, DEC-26, DEC-27, DEC-35).
   - **Given** the challenge's sample files in `data/`, **When** `bin/run` runs with no arguments, **Then**:
     - Standard output is exactly:

       ```
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

       Output file: output/final_balances_2026-11-07_143005.csv
       ```

     - Standard error: (nothing)
     - Exit status: 0
     - And `output/final_balances_2026-11-07_143005.csv` holds exactly:

       ```
       1111234522226789,4820.50
       1111234522221234,9974.40
       2222123433331212,1550.00
       1212343433335665,1725.60
       3212343433335755,48679.50
       ```

     - The closing balance of every account ([DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)):

       | Account | Starting balance | Closing balance |
       |---|---:|---:|
       | 1111234522226789 | 5000.00 | 4820.50 |
       | 1111234522221234 | 10000.00 | 9974.40 |
       | 2222123433331212 | 550.00 | 1550.00 |
       | 1212343433335665 | 1200.00 | 1725.60 |
       | 3212343433335755 | 50000.00 | 48679.50 |
       | **Total** | **66750.00** | **66750.00** |

   - Test: the end-to-end spec runs `bin/run data/mable_account_balances.csv data/mable_transactions.csv output/final_balances_2026-11-07_143005.csv` in a temporary folder holding the copies from `spec/fixtures/sample/` under `data/`, so standard output, standard error and the file are exactly the above (decided in the run, items 1 and 2; page 9 pick 48). That `bin/run` with no arguments uses `data/` and the default path is AC-09.1.

---

### User Story 2 - The balances file is loaded, or every problem in it is reported (Priority: P1)

The program loads every account and its starting balance from the balances file, accepting the common CSV forms. If the file has any problem, the run stops before any transfer, listing every problem with its physical line number, so the user can fix them all at once ([FR-01](../../docs/solution-design/02-functional-requirements.md#fr-01-load-the-balances-file); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04) to [DEC-12](../../docs/design-analysis/design-decisions.md#dec-12), [DEC-31](../../docs/design-analysis/design-decisions.md#dec-31)).

**Why this priority**: every transfer depends on the starting balances, so doubtful balances must never be used.

**Independent Test**: `LoadBalances` with a fake reader giving rows from memory and a real `AccountRepository` (unit); `BalancesCsvReader` with fixture files (integration); the runner scenarios below with real CSV files.

**Acceptance Scenarios**:

1. **AC-01.1 A valid file is loaded, including leading zeros and a $0.00 balance** (FR-01; DEC-08, DEC-10).
   - **Given** `balances.csv` and a `transfers.csv` holding `1111234522226789,1212343433335665,10.00`, **When** the program runs, **Then**:
     - Standard output: Template A with `1111234522226789 -> 1212343433335665  10.00` and the balances `90.00`, `60.00`, `0.00` **(derived)**: the final balances list all three accounts in file order, with `0000123412341234` kept as written and its balance `0.00` accepted.
     - Standard error: (nothing)
     - Exit status: 0
2. **AC-01.2 Common CSV forms are accepted** (FR-01; DEC-04).
   - **Given** a `balances.csv` that starts with a UTF-8 byte-order mark, uses Windows line endings, has no final newline, and whose line 1 is `"1111234522226789", 100.00 ` (a quoted value and spaces around values), followed by lines 2 and 3 of `balances.csv`, and the `transfers.csv` of AC-01.1, **When** the program runs, **Then** the account is loaded as `1111234522226789` with balance `100.00`, exactly as if the line were `1111234522226789,100.00`:
     - Standard output: exactly that of AC-01.1.
     - Standard error: (nothing)
     - Exit status: 0
3. **AC-01.3 Blank lines are skipped but still counted in line numbers** (FR-01; DEC-05, DEC-07).
   - **Given** a `balances.csv` whose line 1 is `1111234522226789,100.00`, line 2 is empty, line 3 holds only spaces and line 4 is `12345,50.00` (decided in the run, item 9), **When** the program runs, **Then** neither blank line is an error or an account, and the row on line 4 is reported as line 4:
     - Standard output: (nothing)
     - Standard error **(derived)**:

       ```
       Error: the balances file is invalid (1 problem):
         Line 4: account number "12345" must be exactly 16 digits
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
       ```

     - Exit status: 1
4. **AC-01.4 An invalid file reports every problem and stops the run** (FR-01; DEC-07, DEC-11, DEC-12).
   - **Given** this `balances.csv` (line 2 is empty):

     ```
     1111234522226789,5000.00

     12345,100.00
     1212343433335665,abc,9
     1111234522226789,10.00
     2222123433331212,-5.00
     3212343433335755,1.234
     ```

   - **When** the program runs, **Then** no transfer is read or applied and no output file is written:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the balances file is invalid (5 problems):
         Line 3: account number "12345" must be exactly 16 digits
         Line 4: expected 2 fields, found 3
         Line 5: account 1111234522226789 appears more than once (first on line 1)
         Line 6: balance "-5.00" must not be negative
         Line 7: balance "1.234" has more than 2 decimal places
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 5 problems
       ```

     - Exit status: 1
   - This is the invalid-balances end-to-end run (decided in the run, item 2).
5. **AC-01.5 A row with several problems reports each one, in field order** (FR-01; DEC-12).
   - **Given** a `balances.csv` whose only line is `12345,abc`, **When** the program runs, **Then**:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the balances file is invalid (2 problems):
         Line 1: account number "12345" must be exactly 16 digits
         Line 1: balance "abc" is not a valid amount
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
       ```

     - Exit status: 1
6. **AC-01.6 Other balance problems** (FR-01; DEC-04, DEC-09, DEC-11, DEC-12).
   - **Given** a `balances.csv` whose line 1 is `1212343433335665,50.00` (decided in the run, item 9) and whose line 2 is the row below, **When** the program runs, **Then** standard output is (nothing), standard error is `Error: the balances file is invalid (<count>):`, then the problem lines, then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: <count>`, and
     Exit status: 1:

     | Row on line 2 | Count | Problem lines |
     |---|---|---|
     | `1111234522226789,` | `1 problem` | `  Line 2: balance is empty` |
     | `1111234522226789,abc` | `1 problem` | `  Line 2: balance "abc" is not a valid amount` |
     | `1111234522226789,5000.00,x` | `1 problem` | `  Line 2: expected 2 fields, found 3` |
     | `,` | `2 problems` | `  Line 2: account number "" must be exactly 16 digits` and `  Line 2: balance is empty` |

     A row with the wrong number of fields reports only the field-count problem, because it is not known which value is which.
7. **AC-01.7 A header row makes the file invalid, with a hint** (FR-01; DEC-06).
   - **Given** a `balances.csv` whose line 1 is `account,balance`, followed by the three rows of `balances.csv` on lines 2 to 4 (decided in the run, item 9), **When** the program runs, **Then**:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the balances file is invalid (2 problems):
         Line 1: account number "account" must be exactly 16 digits. This looks like a header row; files must not have a header.
         Line 1: balance "balance" is not a valid amount
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
       ```

     - Exit status: 1
   - With line 1 `1111O34522226789,100.00` instead, the only problem line is `  Line 1: account number "1111O34522226789" must be exactly 16 digits`, with no header hint, because it contains digits, and the count is `1 problem`.
   - With line 1 `account,balance,x` instead, the only problem line is `  Line 1: expected 2 fields, found 3. This looks like a header row; files must not have a header.`, and the count is `1 problem`.
8. **AC-01.8 An empty balances file stops the run** (FR-01; DEC-05, DEC-11).
   - **Given** a balances file `empty.csv` that is empty, or holds only blank lines, **When** `bin/run empty.csv transfers.csv` runs, **Then**:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the balances file has no rows: empty.csv
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem
       ```

     - Exit status: 1
9. **AC-01.9 A balances file that cannot be read past a line** (FR-01; DEC-04, DEC-07, DEC-12).
   - **Given** a balances file `bad.csv` whose lines 1 and 2 are the first two rows of `balances.csv`, line 3 is `12345,100.00`, line 4 is `0000123412341234,0.00`, lines 5 and 6 are empty, and line 7 opens a quote that is never closed (decided in the run, item 9), **When** `bin/run bad.csv transfers.csv` runs, **Then**:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the balances file is invalid (2 problems):
         Line 3: account number "12345" must be exactly 16 digits
         Line 7: cannot read bad.csv from this line. Check for an unclosed quote or characters that are not text.
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
       ```

     - Exit status: 1
10. **AC-01.10 A duplicate account is reported even when its balance is invalid** (FR-01; DEC-12, DEC-31).
    - **Given** a `balances.csv` whose line 1 is `1111234522226789,5000.00` and whose line 2 is `1111234522226789,abc`, **When** the program runs, **Then**:
      - Standard output: (nothing)
      - Standard error:

        ```
        Error: the balances file is invalid (2 problems):
          Line 2: account 1111234522226789 appears more than once (first on line 1)
          Line 2: balance "abc" is not a valid amount
        E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 2 problems
        ```

      - Exit status: 1
    - **Known gap** (DEC-12): with line 1 `1111234522226789,abc` and line 2 `1111234522226789,10.00`, the only problem line is `  Line 1: balance "abc" is not a valid amount` and the count is `1 problem`; the duplicate on line 2 is reported once line 1 is fixed. The run stops either way.
    - The same gap holds for any first copy that is not added (clarified, item 19): with line 1 `1111234522226789,5000.00,x` and line 2 `1111234522226789,10.00`, the only problem line is `  Line 1: expected 2 fields, found 3` and the count is `1 problem`; with line 1 `1111234522226789,-5.00` instead, it is `  Line 1: balance "-5.00" must not be negative`.
11. **The balances file is checked before the transfers file** (FR-01, FR-02; DEC-12, DEC-20).
    - **Given** an invalid `balances.csv` (for example AC-01.5) and an empty `transfers.csv`, **When** the program runs, **Then** only the balances error is shown: standard output (nothing), standard error exactly as in AC-01.5, exit status 1 (AC-02.4).

---

### User Story 3 - The transfers file is read one row at a time, in file order (Priority: P1)

The program reads the transfers file one row at a time, in file order, gives each row its physical line number, applies each transfer once, never retries a rejected one, and treats every row as a separate transfer. A bad row is rejected with one reason and the run continues. An empty transfers file, or one that cannot be read past a line, stops the run ([FR-02](../../docs/solution-design/02-functional-requirements.md#fr-02-read-the-transfers-file), [FR-07](../../docs/solution-design/02-functional-requirements.md#fr-07-the-order-transfers-are-applied-in); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04) to [DEC-07](../../docs/design-analysis/design-decisions.md#dec-07), [DEC-14](../../docs/design-analysis/design-decisions.md#dec-14) to [DEC-16](../../docs/design-analysis/design-decisions.md#dec-16), [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19) to [DEC-21](../../docs/design-analysis/design-decisions.md#dec-21), [DEC-32](../../docs/design-analysis/design-decisions.md#dec-32)).

**Why this priority**: applying the day's transfers in the company's order is the job of the program.

**Independent Test**: `ProcessDailyTransfer` with fake readers giving rows from memory, a memory logger and a fixed run time (unit); `TransfersCsvReader` with fixture files (integration); the runner scenarios below.

**Acceptance Scenarios**:

1. **AC-02.1 Blank lines are skipped; a row with the wrong number of fields is rejected and the run continues** (FR-02; DEC-04, DEC-05, DEC-07, DEC-14, DEC-19, DEC-28).
   - **Given** `balances.csv` and this `transfers.csv` (line 2 is empty; line 3 holds only spaces):

     ```
     1111234522226789,1212343433335665,10.00


     1111234522226789,1212343433335665
     1212343433335665,1111234522226789,5.00
     ```

   - **When** the program runs, **Then**:
     - Standard output (the transfers section and the summary counts are from page 2; the rest is **derived**):

       ```
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
       ```

     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 4 rejected: ************6789 -> ************5665 malformed_row
       ```

     - Exit status: 0
   - In the log line of a row with the wrong number of fields, the fields are taken by position (from, to, amount); fields the row does not have are left out, and fields after the third are not logged.
2. **AC-02.2 A line of commas is a row with empty fields** (FR-02; DEC-05, DEC-06, DEC-21).
   - **Given** `balances.csv` and a `transfers.csv` whose line 1 is `,,`, **When** the program runs, **Then** the row is rejected (an empty first field is not a header):
     - Standard output: Template R with the transfers line `  Line 1  rejected  "" -> ""  ""  invalid_account_number` and the reason code `invalid_account_number` **(derived)**.
     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** "" invalid_account_number
       W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
       ```

     - Exit status: 0
3. **AC-02.3 A header row is rejected with a hint; every row rejected gives a warning but still completes** (FR-02; DEC-06, DEC-21, DEC-26).
   - **Given** `balances.csv` and a `transfers.csv` holding only `from,to,amount`, **When** the program runs, **Then** the output file is written with the balances unchanged, and:
     - Standard output:

       ```
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
       ```

     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** amount invalid_account_number
       W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.
       ```

     - Exit status: 0
     - And the output file holds exactly the three lines of `balances.csv`, each ending with a line feed.
   - This is the all-rejected end-to-end run (decided in the run, item 2).
   - With `transfers.csv` holding only `from,to` instead: standard output is Template R with the transfers line `  Line 1  rejected  malformed_row: 2 fields, expected 3. This looks like a header row; files must not have a header.` and the reason code `malformed_row` **(derived)**; standard error is `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: **** -> **** malformed_row` **(derived)**, then the all-rejected warn line; exit status 0.
4. **AC-02.4 An empty transfers file stops the run** (FR-02; DEC-05, DEC-20).
   - **Given** `balances.csv` and a transfers file `empty.csv` that is empty, or holds only blank lines, **When** `bin/run balances.csv empty.csv` runs, **Then** no output file is written, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the transfers file has no transfers: empty.csv
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: transfers file has no transfers
       ```

     - Exit status: 1
   - And if the balances file is also invalid, only the balances error from FR-01 is shown, because the balances file is checked first (User Story 2, scenario 11).
5. **AC-02.5 A transfers file that cannot be read past a line stops the run, discarding earlier transfers** (FR-02; DEC-04, DEC-07, DEC-25).
   - **Given** `balances.csv` and a `bad.csv` whose line 1 is `1111234522226789,1212343433335665,10.00` and whose line 2 opens a quote that is never closed, **When** `bin/run balances.csv bad.csv` runs, **Then** the transfer on line 1 is discarded, no output file is written, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: cannot read bad.csv from line 2. Check for an unclosed quote or characters that are not text.
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
       ```

     - Exit status: 1
   - Any warn lines for rows rejected before line 2 appear above these lines. With line 1 `1111234522226789,1212343433335665,100.01` instead, standard error starts with `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds` **(derived)**, then the two lines above.
6. **AC-07.1 One pass, no retry, repeats applied** (FR-07; DEC-15, DEC-16).
   - **Given** `balances.csv` and this `transfers.csv`:

     ```
     0000123412341234,1212343433335665,20.00
     1111234522226789,0000123412341234,20.00
     1111234522226789,0000123412341234,20.00
     ```

   - **When** the program runs, **Then** line 1 is rejected as `insufficient_funds` and is not retried, even though lines 2 and 3 later pay 40.00 into that account; lines 2 and 3 are both applied:
     - Standard output (the final balances are from page 2; the rest is **derived**):

       ```
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
       ```

     - Standard error **(derived)**:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************5665 20.00 insufficient_funds
       ```

     - Exit status: 0

---

### User Story 4 - A completed run checks the total, writes a new output file, then prints the report (Priority: P1)

At the end of a completed run the program checks that the total of all balances has not changed, writes the final balances to a new CSV file that can be the next day's balances file, and then prints the report on standard output. It never overwrites a file, and nothing is written or printed when the run stops ([FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output); [DEC-24](../../docs/design-analysis/design-decisions.md#dec-24), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).

**Why this priority**: the output file is the next day's input and the report is the user's feedback; a wrong total must never reach either.

**Independent Test**: `ProcessDailyTransfer` with a fake repository whose total changes and a fake reporter (unit); `FinalBalancesCsvWriter` and `ReportPrinter` with a temporary folder (integration); the mixed-rejections end-to-end run.

**Acceptance Scenarios**:

1. **AC-08.2 A day with mixed rejections** (FR-08; DEC-14, DEC-19, DEC-26, DEC-27, DEC-28).
   - **Given** `balances.csv` and this `transfers.csv`:

     ```
     1111234522226789,1212343433335665,30.00
     1111234522226789,1212343433335665,90.00
     1212343433335665,9999888877776666,10.00
     1111234522226789,0000123412341234,70.00
     1212343433335665,1212343433335665,5.00
     ```

   - **When** the program runs, **Then**:
     - Standard output:

       ```
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
       ```

     - Standard error:

       ```
       W, [<timestamp> #<pid>]  WARN -- : Line 2 rejected: ************6789 -> ************5665 90.00 insufficient_funds
       W, [<timestamp> #<pid>]  WARN -- : Line 3 rejected: ************5665 -> ************6666 10.00 unknown_account
       W, [<timestamp> #<pid>]  WARN -- : Line 5 rejected: ************5665 -> ************5665 5.00 same_account
       ```

     - Exit status: 0
     - And the output file holds exactly:

       ```
       1111234522226789,0.00
       1212343433335665,80.00
       0000123412341234,70.00
       ```

   - This is the mixed-rejections end-to-end run (decided in the run, item 2).
2. **AC-08.3 The output file** (FR-08; DEC-27; page 2 pick 17).
   - **Given** any completed run, **Then** the output file has no header, one account per line as `account number,balance`, full account numbers, balances with exactly 2 decimal places, in load order: the same format as the balances file, so it can be the next day's balances file.
   - Every line, the last one included, ends with a line feed (LF) only, on every operating system.
   - With no third argument, the file is `output/final_balances_YYYY-MM-DD_HHMMSS.csv`, named from the local date and time the run started (24-hour clock): for the run time 2026-11-07 14:30:05, `FinalBalancesCsvWriter.default_path` gives `output/final_balances_2026-11-07_143005.csv`.
   - With a third argument, that path is used as given, and any missing folders on it are created: `bin/run balances.csv transfers.csv out/new/day1.csv` with no `out/` folder creates `out/new/day1.csv`, (the transfers file of AC-01.1). Standard output: Template A with `1111234522226789 -> 1212343433335665  10.00` and the balances `90.00`, `60.00`, `0.00`, with the last line `Output file: out/new/day1.csv` **(derived)**; standard error: (nothing); exit status: 0.
   - Feeding the output file of AC-08.2 back in as the balances file loads the three accounts with balances `0.00`, `80.00` and `70.00` (DEC-27). **Given** `balances.csv` holding the three lines of AC-08.2's output file and this `transfers.csv`:

     ```
     1212343433335665,1111234522226789,10.00
     ```

     **When** `bin/run balances.csv transfers.csv` runs at the run time 2026-11-07 14:30:05, **Then**:
     - Standard output: Template A with `1212343433335665 -> 1111234522226789  10.00`, the opening balances `0.00`, `80.00`, `70.00` and the balances `10.00`, `70.00`, `70.00` **(derived)**.
     - Standard error: (nothing)
     - Exit status: 0
3. **AC-08.4 The output path is shown relative to where the command was run, or in full when the file is outside that folder** (FR-08; DEC-26).
   - **Given** the sample files, **When** `bin/run` runs with no arguments from the project root, **Then** standard output is AC-08.1's report, whose last line is `Output file: output/final_balances_2026-11-07_143005.csv` **(derived)**.
   - **And when** `../bin/run` runs with no arguments from the project's `docs` folder, the output file is outside that folder, so standard output is AC-08.1's report with the last line `Output file: <project root>/output/final_balances_2026-11-07_143005.csv`, where `<project root>` is the full path of the project folder **(derived)**.
   - **And when** a third argument names a file outside the current folder, such as `/tmp/day1.csv`, standard output is AC-08.1's report with the last line `Output file: /tmp/day1.csv`, the full path **(derived)**.
   - Standard error: (nothing); exit status: 0, in all three.
   - Test: `ReportPrinter` with a `DayResult` whose output path is inside or below the current folder, or outside it (in another folder of its parent, or elsewhere); every runner scenario run from the temporary folder with the default arguments, whose last line is `Output file: output/final_balances_2026-11-07_143005.csv` (for example AC-01.1); a runner scenario run from a subfolder of the temporary folder with `../balances.csv ../transfers.csv ../output/final_balances_2026-11-07_143005.csv`, whose standard output is Template A (`1111234522226789 -> 1212343433335665  10.00`; balances `90.00`, `60.00`, `0.00`) with the last line `Output file: ` followed by the full path of `output/final_balances_2026-11-07_143005.csv` in the temporary folder; and one with an output path in a second temporary folder, whose standard output is Template A with the last line `Output file: ` followed by that full path (decided in the run, item 3).
4. **AC-08.5 A changed total stops the run** (FR-08; DEC-24, DEC-25; page 9 picks 46 and 47).
   - **Given** the sample files and a fault that makes the total after the transfers (66749.00) differ from the total before (66750.00); with correct code this cannot happen, so the test creates it on purpose. **When** the run reaches the end of the transfers, **Then** no output file is written and no report is printed, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: the total of all balances changed from 66750.00 to 66749.00. No output file was written.
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: total of all balances changed
       ```

     - Exit status: 1
   - Test, split across two specs (page 9 pick 46): the `ProcessDailyTransfer` spec passes a fake repository whose total changes after the transfers, a fake reporter and the real `FinalBalancesCsvWriter` with an output path in a temporary folder, and checks that `TotalChanged` is raised with the message `the total of all balances changed from 66750.00 to 66749.00. No output file was written.`, that the file does not exist and that the reporter was never called. The `Runner` spec stubs `ProcessDailyTransfer.new` to return a stand-in whose run raises that `TotalChanged`, and checks standard output (nothing), the two standard error lines above and exit status 1.
5. **The report is printed once, after the output file is written** (FR-08; DEC-26).
   - **Given** a completed run, **When** `ProcessDailyTransfer` finishes, **Then** the reporter was called exactly once, with a `DayResult` holding the `TransferResult`s in file order, the totals before and after, the opening balances, the final accounts in load order and the output path, and the output file already existed at that moment.
6. **AC-09.4 An output file that cannot be written stops the run** (FR-08, FR-09; DEC-25, DEC-27; page 2 pick 14).
   - **Given** `balances.csv`, the `transfers.csv` of AC-01.1, and a third argument `out` that names an existing folder, **When** `bin/run balances.csv transfers.csv out` runs, **Then** no file is left behind, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: cannot write output file out: <reason from the system>
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot write output file
       ```

     - Exit status: 1
   - A path that is an existing folder gives this error, not the "already exists" error. If writing fails partway, `FinalBalancesCsvWriter` deletes the partial file it created before raising `OutputNotWritable`. If the file appears after the start checks, `OutputNotWritable` is raised and that file is left unchanged (page 6 pick 40).

---

### User Story 5 - The runner starts the run, reports every stop clearly and sets the exit status (Priority: P1)

A user runs `bin/run` with 0, 2 or 3 positional arguments. The runner checks the arguments and the files before reading anything, reports every start problem together, logs at the level `LOG_LEVEL` sets with account numbers masked, prints a clear message for every stopped run with no Ruby stack trace, and exits with 0 for a completed run and 1 for a stopped one ([FR-09](../../docs/solution-design/02-functional-requirements.md#fr-09-the-runner); [DEC-02](../../docs/design-analysis/design-decisions.md#dec-02), [DEC-03](../../docs/design-analysis/design-decisions.md#dec-03), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-23](../../docs/design-analysis/design-decisions.md#dec-23), [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28), [DEC-29](../../docs/design-analysis/design-decisions.md#dec-29)).

**Why this priority**: it is how the user starts the program and learns whether the run completed.

**Independent Test**: `Runner` integration specs in a temporary folder, with real CSV files, and with a stand-in `ProcessDailyTransfer` where only the runner's own behaviour is checked; the usage end-to-end run.

**Acceptance Scenarios**:

1. **AC-09.1 Arguments** (FR-09; DEC-22, DEC-27).

   | Command | Balances | Transfers | Output |
   |---|---|---|---|
   | `bin/run` | `data/mable_account_balances.csv` | `data/mable_transactions.csv` | default name in `output/` |
   | `bin/run b.csv t.csv` | `b.csv` | `t.csv` | default name in `output/` |
   | `bin/run b.csv t.csv out/day1.csv` | `b.csv` | `t.csv` | `out/day1.csv` |

   - Standard output, standard error and exit status **(derived**, as page 2 prints none of them for this scenario**)**, for input files that are valid: `bin/run` with no arguments: standard output is AC-08.1's report, with the run's default `Output file:` line; standard error (nothing); exit status 0. `bin/run b.csv t.csv`: a completed run whose last report line is `Output file:` with the default output path; standard error (nothing); exit status 0. `bin/run b.csv t.csv out/day1.csv`: a completed run whose last report line is `Output file: out/day1.csv`; standard error (nothing); exit status 0.
   - Typed paths are relative to the current folder. The default paths (`data/...` and `output/...`) are relative to the project root, so `bin/run` with no arguments works from any folder.
   - Test: the `Runner` spec, from a temporary current folder, stubs `ProcessDailyTransfer.new` with a stand-in that records the run time and the paths it is given (decided in the run, item 3), and checks: with no arguments, the project root's `data/mable_account_balances.csv` and `data/mable_transactions.csv` and the project root joined with `FinalBalancesCsvWriter.default_path` for the recorded run time; with 2 arguments, the two typed paths in the current folder and the same default output path; with 3, the third typed path. Nothing is written in the project's `output/`.
2. **AC-09.2 Wrong number of arguments** (FR-09; DEC-22).
   - **Given** any folder, **When** `bin/run` runs with 1 argument, or with 4 or more, including `bin/run -h` and `bin/run --help`, **Then** no file is read or written, and:
     - Standard output: (nothing)
     - Standard error, exactly:

       ```
       Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
       With no arguments, runs the sample files in data/.
       ```

     - Exit status: 1
   - There is no log line, because the run never started. `bin/run` with 1 argument is the usage end-to-end run (DEC-34).
3. **AC-09.3 Start checks are reported together** (FR-09; DEC-23, DEC-25).
   - **Given** that neither `missing1.csv` nor `missing2.csv` exists, and `out/day1.csv` already exists, **When** `bin/run missing1.csv missing2.csv out/day1.csv` runs, **Then** no file is read and `out/day1.csv` is unchanged, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: file not found: missing1.csv
       Error: file not found: missing2.csv
       Error: output file already exists: out/day1.csv. Delete it or give another output path.
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found, output file already exists)
       ```

     - Exit status: 1
   - Every problem found at the start gets its own `Error:` line, in the order balances, transfers, output, followed by one log line that lists only the reasons that occurred.
   - With only the two missing files (no third argument and no file at the default path): standard output (nothing); standard error the first two `Error:` lines above, then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (file not found)`; exit status 1.
   - With only an existing output file, `bin/run balances.csv transfers.csv out/day1.csv`: no transfer is read and `out/day1.csv` is unchanged; standard output (nothing); standard error `Error: output file already exists: out/day1.csv. Delete it or give another output path.` then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)`; exit status 1.
4. **AC-09.3a An input file that cannot be opened stops the run** (FR-09; DEC-23, DEC-25; page 2 pick 16).
   - **Given** `balances.csv` exists but cannot be opened (permission denied), **When** `bin/run balances.csv transfers.csv` runs, **Then** no output file is written, and:
     - Standard output: (nothing)
     - Standard error:

       ```
       Error: cannot read file balances.csv: <reason from the system>
       E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot read file
       ```

     - Exit status: 1
   - The same holds for a transfers file that cannot be opened: `Error: cannot read file transfers.csv: <reason from the system>`, then the same log line. This problem is found when the file is opened, after the start checks have passed. How the test makes a file that exists but cannot be opened is decided in the run, item 11.
5. **AC-09.5 Log level** (FR-09; DEC-28, DEC-29).
   - **Given** the sample files in `data/`, **When** `LOG_LEVEL=info bin/run` runs (`INFO` and `Info` work the same), **Then**:
     - Standard output: exactly the report in AC-08.1.
     - Standard error:

       ```
       I, [<timestamp> #<pid>]  INFO -- : Run started: balances data/mable_account_balances.csv, transfers data/mable_transactions.csv
       I, [<timestamp> #<pid>]  INFO -- : Line 1 applied: ************6789 -> ************5665 500.00
       I, [<timestamp> #<pid>]  INFO -- : Line 2 applied: ************5755 -> ************1212 1000.00
       I, [<timestamp> #<pid>]  INFO -- : Line 3 applied: ************5755 -> ************6789 320.50
       I, [<timestamp> #<pid>]  INFO -- : Line 4 applied: ************1234 -> ************5665 25.60
       I, [<timestamp> #<pid>]  INFO -- : Run ended: processed 4, applied 4, rejected 0
       ```

     - Exit status: 0
   - With `LOG_LEVEL` unset, `warn`, or any other value such as `debug`, the level is warn. For the sample run: standard output is exactly the report in AC-08.1; standard error is (nothing); exit status 0.
   - At info level, a run that passes the start checks and then stops logs `Run started: ...` first, then the info and warn lines of the rows read before the stop, then the `Error:` line(s) and the error log line, and never `Run ended` (clarified, item 20). For AC-01.4 with `LOG_LEVEL=info`, standard error is `I, [<timestamp> #<pid>]  INFO -- : Run started: balances balances.csv, transfers transfers.csv` **(derived)** followed by the lines of AC-01.4. Standard output is (nothing); exit status 1. A run stopped by the arguments or the start checks logs no info line.
   - At info level, a run with rejections ends with, for example, `Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)`: for AC-08.2 with `LOG_LEVEL=info`, standard error is **(derived)** `Run started: balances balances.csv, transfers transfers.csv` (info), `Line 1 applied: ************6789 -> ************5665 30.00` (info), the Line 2 and Line 3 warn lines of AC-08.2, `Line 4 applied: ************6789 -> ************1234 70.00` (info), the Line 5 warn line, then `Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)` (info), each in the log format `I, [<timestamp> #<pid>]  INFO -- : ` or `W, [<timestamp> #<pid>]  WARN -- : `. Standard output is exactly AC-08.2's report; exit status 0.
6. **AC-09.6 Account numbers are masked only in log lines** (FR-09; DEC-26, DEC-29).
   - Log lines show 12 asterisks and the last 4 characters: `************6789`. A value that is not a valid account number is masked the same way (`12345` becomes `*2345`), and a value of 4 characters or fewer, including an empty value, becomes `****`.
   - The report, the error messages and the output file show full account numbers. Error log lines show no account numbers at all.
   - **(derived)** **Given** the sample files in `data/`, **When** `LOG_LEVEL=info bin/run` runs, **Then**:
     - Standard output: exactly the report in AC-08.1, with every account number in full (for example `1111234522226789`).
     - Standard error: exactly the six info lines of AC-09.5, with every account number masked as `************NNNN` and no run of 16 digits.
     - Exit status: 0
   - **(derived)** A stopped run (AC-01.4 with `LOG_LEVEL=info`): standard output (nothing); standard error as in AC-09.5's stopped-run example, with full account numbers in the `Error:` lines and none in the error log line; exit status 1.
7. **AC-09.7 Every run starts from the balances file** (FR-09; DEC-02, DEC-03, DEC-27).
   - **Given** the sample files, **When** `bin/run` runs twice, one second apart, **Then** both runs give the same report and the same final balances, and each writes its own file (`..._143005.csv` and `..._143006.csv`). For both runs: standard output is AC-08.1's report apart from the `Output file:` line, which shows the run's own file; standard error (nothing); exit status 0. Nothing in the report, the logs or the output names a company.
   - Test (decided in the run, item 4): `FinalBalancesCsvWriter.default_path` gives `output/final_balances_2026-11-07_143005.csv` and `output/final_balances_2026-11-07_143006.csv` for run times one second apart; two runner runs on the same sample files, with the two output paths, give identical standard output apart from the `Output file:` line and identical output files.
8. **AC-09.8 Exit status** (FR-09; DEC-25).
   - 0 for every completed run, even if some or all transfers were rejected (AC-02.3, AC-08.2).
   - 1 for every stopped run: wrong arguments (AC-09.2), a missing input file (AC-09.3) or one that cannot be opened (AC-09.3a), an invalid balances file (AC-01.3 to AC-01.10), an empty transfers file (AC-02.4), a file that cannot be read past a line (AC-01.9, AC-02.5), a changed total (AC-08.5), an output file that already exists (AC-09.3), or an output file that cannot be written (AC-09.4).
   - Standard error: for exit status 0, nothing unless a transfer was rejected (warn lines, AC-09.5) or `LOG_LEVEL` asks for more; for exit status 1, the `Error:` lines and the error log line of the scenario that stopped the run.
   - Every exit status 1 means standard output is (nothing), no output file is written, and an output file that already existed is unchanged.

---

### User Story 6 - Every domain scenario gives its exact run outcome (Priority: P2)

The page 2 scenarios of FR-03 to FR-06 are owned by `001-domain`. This spec runs each of them through the runner with real CSV files, so the user sees exactly the report line, log line and exit status page 2 describes (brief rule 4; [DEC-14](../../docs/design-analysis/design-decisions.md#dec-14), [DEC-19](../../docs/design-analysis/design-decisions.md#dec-19), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28), [DEC-29](../../docs/design-analysis/design-decisions.md#dec-29)).

**Why this priority**: the domain rules are proven in `001`; this proves the runner shows their outcome exactly.

**Independent Test**: one runner scenario per row below, with `balances.csv` and a one-row `transfers.csv`.

**Acceptance Scenarios**: in every row, the command is `bin/run balances.csv transfers.csv`, the row is line 1 of `transfers.csv`, and the exit status is 0. "R" means standard output is Template R with the transfers line shown and that line's reason code, and standard error is the warn line shown followed by the all-rejected warn line. "A" means standard output is Template A with the values and balances shown, and standard error is (nothing). Every line marked **(derived)** in `001` is derived here the same way.

1. **FR-03** (owned by `001`; DEC-13, DEC-14, DEC-18, DEC-19):

   | Criterion | Row | Standard output | Standard error |
   |---|---|---|---|
   | AC-03.1 | `1111234522226789,1212343433335665,30.00` | A, with the transfers line `  Line 1  applied  1111234522226789 -> 1212343433335665  30.00` and the closing balances 70.00, 80.00 and 0.00 (openings 100.00, 50.00 and 0.00) | (nothing) |
   | AC-03.3 | `12345,1212343433335665,abc` | R: `  Line 1  rejected  12345 -> 1212343433335665  abc  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: *2345 -> ************5665 abc invalid_account_number` **(derived)** |
   | AC-03.3 | `1111234522226789,1111234522226789,0` | R: `  Line 1  rejected  1111234522226789 -> 1111234522226789  0  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************6789 0 invalid_amount` **(derived)** |
   | AC-03.3 | `9999888877776666,9999888877776666,5.00` | R: `  Line 1  rejected  9999888877776666 -> 9999888877776666  5.00  same_account` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6666 -> ************6666 5.00 same_account` **(derived)** |

   - Exit status: 0 for every row of this table.
   - **AC-03.2** (a rejected transfer changes nothing and the run continues; standard output and standard error as in the rows above; Exit status: 0) is shown by every R row above and in FR-04 to FR-06 (both balances unchanged in the final balances), and by AC-08.2 (the row after a rejected one is processed; exit status 0).
   - The order in which `ProcessDailyTransfer` builds the values, both `AccountNumber`s before the `Money`, is owned here (FR-014 below); it gives `invalid_account_number` for `12345,1212343433335665,abc`.
2. **FR-04** (owned by `001`; DEC-10, DEC-13):

   | Criterion | Row | Standard output | Standard error |
   |---|---|---|---|
   | AC-04.1 | `1111234522226789,1212343433335665,100.01` | R: `  Line 1  rejected  1111234522226789 -> 1212343433335665  100.01  insufficient_funds` | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 100.01 insufficient_funds`, then `W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.` |
   | AC-04.2 | `1111234522226789,1212343433335665,100.00` | A: `1111234522226789 -> 1212343433335665  100.00` **(derived)**; closing balances 0.00, 150.00 and 0.00 (openings 100.00, 50.00 and 0.00) | (nothing) |
   | AC-04.3 | `0000123412341234,1111234522226789,0.01` | R: `  Line 1  rejected  0000123412341234 -> 1111234522226789  0.01  insufficient_funds` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************6789 0.01 insufficient_funds` **(derived)** |

   - Exit status: 0 for every row of this table.

3. **FR-05** (owned by `001`; DEC-17):

   | Criterion | Row | Standard output | Standard error |
   |---|---|---|---|
   | AC-05.1 | `1111234522226789,9999888877776666,10.00` | R: `  Line 1  rejected  1111234522226789 -> 9999888877776666  10.00  unknown_account`; the final balances list only the three loaded accounts | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************6666 10.00 unknown_account`, then `W, [<timestamp> #<pid>]  WARN -- : All transfers were rejected; check this is the right file.` |
   | AC-05.2 | `9999888877776666,1111234522226789,10.00` | R: `  Line 1  rejected  9999888877776666 -> 1111234522226789  10.00  unknown_account` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6666 -> ************6789 10.00 unknown_account` **(derived)** |

   - Exit status: 0 for every row of this table.

4. **AC-06.1 Account numbers** (FR-06, owned by `001`; DEC-08). The row is `<from>,1212343433335665,10.00`:

   | From value | Standard output | Standard error |
   |---|---|---|
   | `1111234522226789` | A: `1111234522226789 -> 1212343433335665  10.00`; balances `90.00`, `60.00`, `0.00` **(derived)** | (nothing) |
   | `0000123412341234` | R: `  Line 1  rejected  0000123412341234 -> 1212343433335665  10.00  insufficient_funds` **(derived)** (the leading zeros match the balances file) | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************1234 -> ************5665 10.00 insufficient_funds` **(derived)** |
   | `111123452222678` | R: `  Line 1  rejected  111123452222678 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ***********2678 -> ************5665 10.00 invalid_account_number` **(derived)** |
   | `11112345222267890` | R: `  Line 1  rejected  11112345222267890 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: *************7890 -> ************5665 10.00 invalid_account_number` **(derived)** |
   | `1111O34522226789` | R: `  Line 1  rejected  1111O34522226789 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 10.00 invalid_account_number` **(derived)** |
   | `1111-2345-2222-6789` | R: `  Line 1  rejected  1111-2345-2222-6789 -> 1212343433335665  10.00  invalid_account_number` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ***************6789 -> ************5665 10.00 invalid_account_number` **(derived)** |

   - Exit status: 0 for every row of this table.
   - The account number with leading zeros matched across both files is also an integration test with fixture files (DEC-34).
5. **AC-06.2 Amounts** (FR-06, owned by `001`; DEC-09, DEC-10). The row is `1111234522226789,1212343433335665,<amount>`:

   | Amount as written | Standard output | Standard error |
   |---|---|---|
   | `10` | A: `1111234522226789 -> 1212343433335665  10.00`; balances `90.00`, `60.00`, `0.00` **(derived)** | (nothing) |
   | `10.5`, `10.50` | A: `1111234522226789 -> 1212343433335665  10.50`; balances `89.50`, `60.50`, `0.00` **(derived)** | (nothing) |
   | `007.50` | A: `1111234522226789 -> 1212343433335665  7.50`; balances `92.50`, `57.50`, `0.00` **(derived)** | (nothing) |
   | `0`, `0.00`, `-5.00`, `-0`, `-0.00`, `1.234`, `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0` | R: `  Line 1  rejected  1111234522226789 -> 1212343433335665  <as written>  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 <as written> invalid_amount` **(derived)** |
   | empty (row `1111234522226789,1212343433335665,`) | R: `  Line 1  rejected  1111234522226789 -> 1212343433335665  ""  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 "" invalid_amount` **(derived)** |
   | `"1,000.00"` (quoted) | R: `  Line 1  rejected  1111234522226789 -> 1212343433335665  1,000.00  invalid_amount` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 1,000.00 invalid_amount` **(derived)** |
   | `1,000.00` (not quoted: 4 fields) | R: `  Line 1  rejected  malformed_row: 4 fields, expected 3` **(derived)** | `W, [<timestamp> #<pid>]  WARN -- : Line 1 rejected: ************6789 -> ************5665 1 malformed_row` **(derived)** |

   - Exit status: 0 for every row of this table.
   - `<as written>` is the value after trimming spaces: `10.` is shown as `10.`, not `10.00`. An applied amount is shown with 2 decimal places in the report and in the info log line (`LOG_LEVEL=info`).
6. **AC-06.3 The same rules hold in the balances file** (FR-06, owned by `001`; FR-01; DEC-09 to DEC-11): run through the runner by AC-01.4 to AC-01.6 above.

---

### User Story 7 - The run's cost grows only with the size of the two files (Priority: P3)

A whole run takes time and memory in proportion to the rows in the balances file plus the rows in the transfers file, reads the transfers file one row at a time, and keeps nothing between runs ([NFR-03](../../docs/solution-design/03-non-functional-requirements.md#nfr-03); [DEC-03](../../docs/design-analysis/design-decisions.md#dec-03), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26), [DEC-32](../../docs/design-analysis/design-decisions.md#dec-32)).

**Why this priority**: a day's file for one company is small; this keeps the design honest without a timing test.

**Independent Test**: design review of the [time and space table](../../docs/solution-design/09-considerations.md#time-and-space) against the code; no timing test and no large test file (NFR-03).

**Acceptance Scenarios**:

1. **Given** the code, **When** it is reviewed, **Then** no step compares every row with every other row, and a whole run is O(m + n) in time and space for m accounts and n transfer rows (NFR-03; DEC-32).
2. **Given** a transfers file, **When** it is read, **Then** it is read one row at a time, so its text is never held in full; one `TransferResult` per row is kept for the report (NFR-03; DEC-26, DEC-32).
3. **Given** a balances file, **When** it is loaded, **Then** it is read in full before any transfer runs, because all its problems must be found first (NFR-03; DEC-12, DEC-32).
4. **Given** two runs on the same two files, **When** both complete, **Then** they give the same result, and the second costs the same as the first: nothing is kept between runs (NFR-03; DEC-03; AC-09.7).
5. There is no fixed limit on the number of accounts or transfers; the only limit is memory (NFR-03; DEC-32).

---

### User Story 8 - The tests prove every behaviour once, in any order (Priority: P2)

A developer runs the whole suite and gets orthogonal RSpec specs that read as the behaviour, pass in random order, do not depend on the clock or the terminal, prove the total-check failure that correct code never reaches, and measure coverage ([NFR-06](../../docs/solution-design/03-non-functional-requirements.md#nfr-06); [DEC-24](../../docs/design-analysis/design-decisions.md#dec-24), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28), [DEC-30](../../docs/design-analysis/design-decisions.md#dec-30), [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).

**Why this priority**: the rubric assesses the tests directly: coverage, orthogonality, and tests that explain the functionality.

**Independent Test**: `bundle exec rspec` from a clean checkout, three times with different seeds; review of the test list against DEC-34.

**Acceptance Scenarios**:

1. **Given** the suite, **When** `bundle exec rspec` runs, **Then** every spec passes in random order, each test name prints as a sentence, and SimpleCov measures coverage on every run, with no minimum that fails the run (NFR-06; DEC-34, DEC-36). The README figure is `003`.
2. **Given** the test list, **When** it is reviewed, **Then** each rule is tested once, at the level where it lives: application specs in `spec/application/` with builders, fakes and a fixed run time; infrastructure specs in `spec/infrastructure/` with fixture files or a temporary folder; end-to-end specs in `spec/acceptance/` (NFR-06; DEC-34; page 9 testing strategy).
3. **Given** the fixture files in `spec/fixtures/`, **Then** they are used only for file-level behaviour: blank lines, a header row, a byte-order mark, an unreadable CSV (an unclosed quote), an empty file, a missing file, a wrong number of fields, an account number with leading zeros matched across both files, the end-to-end inputs, and the copies of the challenge's files in `spec/fixtures/sample/` (NFR-06; DEC-34).
4. **Given** the end-to-end specs, **Then** there are exactly five, each running `bin/run` as a separate process: the sample files (AC-08.1), mixed rejections (AC-08.2), all rejected (AC-02.3), an invalid balances file (AC-01.4), and a wrong number of arguments (AC-09.2, 1 argument) (NFR-06; DEC-34, DEC-35; decided in the run, item 2).
5. **Given** `ProcessDailyTransfer`, **When** a test builds it, **Then** it can pass a fixed run time, so the output file name is known, and a logger that writes to memory, so the log lines can be read (NFR-06; DEC-28, DEC-30).
6. **Given** the total-check failure, **Then** its message, no output file, no report and exit status 1 are tested: standard output is (nothing), standard error is the two lines of AC-08.5, and the exit status is 1 (AC-08.5; NFR-06; DEC-24).
7. **Given** the runner scenarios of User Stories 2 to 6, **Then** each checks standard output, standard error and the exit status exactly, with `<timestamp>` and `<pid>` matched as patterns and `<reason from the system>` matched as any non-empty text (decided in the run, items 1 and 10).

---

### Edge Cases

Each has a planned test (DEC-34); the level is given in brackets.

- A balances or transfers file that starts with a byte-order mark, uses Windows line endings or has no final newline gives the same result as a plain file (DEC-04) [integration: byte-order mark fixture; runner scenario AC-01.2].
- A line with only spaces or tabs is blank; a line of commas is a row with empty fields (DEC-05) [integration; AC-02.2].
- Tabs around a value are trimmed like spaces; spaces inside a value are kept (DEC-04, DEC-05; clarified, item 18) [integration].
- Blank lines are not counted as rows but are counted in line numbers (DEC-05, DEC-07) [integration; AC-01.3, AC-02.1].
- A quoted value that spans several lines is reported at the line where the row starts (DEC-07) [integration].
- A header-looking first data row: hint in both files; no hint for a first field with digits or an empty first field; hint after `malformed_row` or the balances field-count problem (DEC-06) [integration: header fixture; AC-01.7, AC-02.2, AC-02.3].
- A header row in the transfers file counts as processed and rejected (DEC-26) [AC-02.3].
- A balances row with the wrong number of fields reports only that problem (page 2 pick 7) [unit; AC-01.4, AC-01.6].
- A balances row with several problems reports each, in field order, the duplicate before the balance problem (DEC-12) [unit; AC-01.5, AC-01.10].
- A duplicate whose first copy has an invalid or negative balance, or the wrong number of fields, is not yet seen as a duplicate (DEC-12 known gap; clarified, item 19) [unit].
- A duplicate account with the same or a different balance is reported naming the first line (DEC-11, DEC-12) [unit; AC-01.4].
- An empty balances file, and one with only blank lines (DEC-11) [unit; integration; AC-01.8].
- An empty transfers file, and one with only blank lines (DEC-20) [unit; integration; AC-02.4].
- An invalid balances file and an empty transfers file together: only the balances error (DEC-12, DEC-20) [User Story 2, scenario 11].
- A balances file that cannot be read past a line: earlier problems first, the unreadable line last, counted as one problem (DEC-04, DEC-12) [unit; integration: unclosed quote fixture; AC-01.9].
- A transfers file that cannot be read past a line: earlier transfers discarded, no output file (DEC-04) [integration; AC-02.5].
- A transfers file whose line 1 already cannot be read stops with `UnreadableFile`, not `NoTransfers` (decided in the run, item 16) [integration].
- Bytes that are not valid UTF-8 text stop the run the same way as an unclosed quote (DEC-04) [integration].
- Every transfer rejected, including a header-only file: completed, warning in the report and the log, exit status 0, output file written (DEC-21) [unit; AC-02.3].
- A rejected transfer is not retried, and two equal rows are both applied (DEC-15, DEC-16) [unit with fake readers; AC-07.1].
- A transfers row with 1, 2, 4 or more fields: `malformed_row`, with the log fields by position (DEC-19, DEC-28; decided in the run, item 8) [unit; integration; AC-02.1].
- The output file already exists at the start: run stops, file unchanged (DEC-25) [integration; AC-09.3].
- The output file appears after the start checks: `OutputNotWritable`, that file unchanged (DEC-27) [integration].
- The output path is an existing folder: `OutputNotWritable`, not "already exists" (DEC-25) [integration; AC-09.4].
- Writing fails partway: the partial file is deleted (DEC-27) [integration].
- Missing folders on the output path are created (DEC-27) [integration; AC-08.3].
- A missing folder on the output path that cannot be created (a file stands where the folder should be): `OutputNotWritable`, no output file (DEC-25, DEC-27; clarified, item 21) [integration].
- The output file uses LF only, the last line included, on every operating system (page 2 pick 17) [integration].
- The output path is shown relative to the current folder when the file is in or below it, and otherwise in full, a file in another folder of the parent included (DEC-26; plan P10) [integration; AC-08.4].
- Both input files missing and the output file existing: three `Error:` lines in the order balances, transfers, output, and one log line (DEC-23, DEC-25) [integration; AC-09.3].
- An input file that exists but cannot be opened (DEC-23) [integration; AC-09.3a].
- 1 argument, 4 or more arguments, `-h` and `--help`: usage message, no log line (DEC-22) [integration; end-to-end with 1 argument; AC-09.2].
- `bin/run` with no arguments from another folder uses the project root's `data/` and `output/` (DEC-22) [integration; AC-09.1, AC-08.4].
- `LOG_LEVEL` unset, `warn`, `info`, `INFO`, `Info`, and another value such as `debug` (DEC-28) [integration; AC-09.5].
- At info level, a run stopped after the start checks logs `Run started` but never `Run ended` (DEC-28; clarified, item 20) [unit; integration; AC-09.5].
- `bin/run` run as a separate process on Windows writes CR LF line endings to standard output and standard error; the end-to-end specs turn them into LF before comparing (NFR-04, DEC-34; clarified, item 22) [end-to-end].
- Masking: a valid number, a value that is not a valid number (`12345` to `*2345`), a value of 4 characters or fewer and an empty value (`****`) (DEC-29) [unit; AC-09.6].
- Error log lines name no account number (DEC-28) [unit; integration].
- The total-check failure (DEC-24) [unit with a fake repository; integration with a stand-in; AC-08.5].
- An unexpected error (a bug) is not caught by the runner: Ruby prints its stack trace and the exit status is 1 (page 9 pick 45) [integration].

## Requirements *(mandatory)*

### Functional Requirements

**Reading the files ([FR-01](../../docs/solution-design/02-functional-requirements.md#fr-01-load-the-balances-file), [FR-02](../../docs/solution-design/02-functional-requirements.md#fr-02-read-the-transfers-file))**

- **FR-001** (FR-01, FR-02; DEC-04, DEC-07): `BalancesCsvReader` and `TransfersCsvReader` MUST read a file with Ruby's CSV library, opened as `bom|utf-8` so a byte-order mark is ignored, accepting quoted values, Windows line endings and a missing final newline, and MUST give each row's values, each trimmed of spaces and tabs around it (spaces and tabs inside a value kept; clarified, item 18), with the row's physical line number (starting at 1, counting blank lines; a row spanning several lines has the line where it starts).
- **FR-002** (FR-01, FR-02; DEC-05): the readers MUST skip a blank line (empty, or only spaces or tabs): it is not a row, not an error and not counted. A line of only commas MUST be a row with empty fields.
- **FR-003** (FR-01, FR-02; DEC-04, DEC-19): the readers MUST mark a row whose number of fields is not 2 (balances) or 3 (transfers) with its field count, instead of raising an error.
- **FR-004** (FR-01, FR-02; DEC-06): the readers MUST mark the first data row with the header hint when its first field is not empty and contains no digits at all. They MUST NOT skip it.
- **FR-005** (FR-01, FR-02, FR-09; DEC-04, DEC-23): the readers MUST raise `UnreadableFile` for a file that cannot be opened, with the message `cannot read file <path>: <reason from the system>`; and for a file the CSV library cannot read past a line (an unclosed quote, or bytes that are not valid UTF-8 text), after giving every row before it, with the line where the unreadable row starts and the message `cannot read <path> from line <N>. Check for an unclosed quote or characters that are not text.`
- **FR-006** (FR-01, FR-02, NFR-03; DEC-32; page 6 pick 36): `BalancesCsvReader` MUST read the whole file; `TransfersCsvReader` MUST give one row at a time, read with Ruby's CSV library (`CSV.open`, one row per `shift`) so each row keeps its physical line number (DEC-07, DEC-32), and never hold the file's text in full. The readers MUST be built without a path and given the path when asked to read. They MUST NOT check account numbers or amounts, build domain models, or check whether the file exists.

**Loading the balances ([FR-01](../../docs/solution-design/02-functional-requirements.md#fr-01-load-the-balances-file))**

- **FR-007** (FR-01; DEC-11, DEC-12, DEC-31; page 6 picks 30, 31): `LoadBalances` MUST take the `BalancesCsvReader`, the balances path and the `AccountRepository`, and for each row, in this order: (1) if the row is marked with the wrong number of fields, report only `expected 2 fields, found <K>` and go to the next row; (2) build the `AccountNumber`; (3) if it is valid, ask `AccountRepository#include?` and, if the number is already held, report the duplicate naming the line where the account first appeared; (4) build the `Money` and run the `Account` opening-balance check; (5) add the `Account` only if the row has no problem, recording that row's line as where the account first appeared. Steps 2 to 4 run separately, so a row reports each of its problems, in field order.
- **FR-008** (FR-01; DEC-06, DEC-07, DEC-12): each problem MUST be one line `Line <N>: <problem>`, where `<problem>` is the domain error's message unchanged (`001`), or `account <number> appears more than once (first on line <M>)` for a duplicate (the `DuplicateAccount` message text followed by ` (first on line <M>)`), or `expected 2 fields, found <K>` for the field count. When the row is marked header-looking, `. This looks like a header row; files must not have a header.` MUST follow the account-number problem, or the field-count problem.
- **FR-009** (FR-01; DEC-04, DEC-12; page 2 pick 9; page 6 pick 33): if the reader raises `UnreadableFile` at a line, `LoadBalances` MUST keep the problems found before it and add `Line <N>: cannot read <path> from this line. Check for an unclosed quote or characters that are not text.` as the last problem, counted as one problem. An `UnreadableFile` for a file that cannot be opened MUST pass through unchanged.
- **FR-010** (FR-01; DEC-11, DEC-12; page 6 pick 32): if any problem is found, `LoadBalances` MUST raise `InvalidBalancesFile` carrying every problem in file order, with the message `the balances file is invalid (<count>):` followed, on separate lines, by each problem line indented by two spaces, where `<count>` is `1 problem` or `<n> problems` (decided in the run, item 6). A file with no rows MUST raise `InvalidBalancesFile` with the single no-rows problem and the message `the balances file has no rows: <path>`.
- **FR-011** (FR-01; DEC-12): `LoadBalances` MUST NOT check digits or money format itself, keep its own list of accounts, stop at the first problem, or apply any transfer. The known gap (a duplicate whose first copy was not added because of its own problem: an invalid or negative balance, or the wrong number of fields) MUST behave as AC-01.10 states (clarified, item 19).

**Running the day ([FR-02](../../docs/solution-design/02-functional-requirements.md#fr-02-read-the-transfers-file), [FR-07](../../docs/solution-design/02-functional-requirements.md#fr-07-the-order-transfers-are-applied-in), [FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output))**

- **FR-012** (FR-02, FR-07, NFR-06; DEC-28, DEC-30; page 6 picks 34, 35): `ProcessDailyTransfer` MUST take in its constructor the run time (defaulting to the current time) and the balances reader, the transfers reader, the writer, the repository, the reporter and the logger as one `ProcessDailyTransfer::Parts`, each by name, and MUST create `LoadBalances` and `TransferService` itself from the parts it was given. It MUST run with the balances path, the transfers path and the output path; when the output path is left out, it MUST use `FinalBalancesCsvWriter.default_path` for its run time.
- **FR-013** (FR-02, FR-07, FR-08; DEC-15, DEC-24, DEC-26, DEC-28; page 6): `ProcessDailyTransfer` MUST, in order: (1) log the run start and load the balances through `LoadBalances`, then note each account's opening balance from `AccountRepository#all` and add them up for the total before; (2) read each transfers row in file order; (3) turn each row into a `TransferResult` (FR-014); (4) log each result; (5) raise `NoTransfers` if there were no rows, and log the all-rejected warning if every row was rejected; (6) add up the total after from `all` and raise `TotalChanged` if it differs from the total before; (7) write the output file through the writer; (8) print the report through the reporter, once; (9) log the run end; and return the `DayResult`. When a run-stopping error is raised after step 1 began, the lines already logged stay and the run end is not logged (clarified, item 20).
- **FR-014** (FR-02, FR-07; DEC-14, DEC-16, DEC-19; page 7.1): for each row, `ProcessDailyTransfer` MUST give a row marked with the wrong number of fields the reason `malformed_row` without building any domain object; otherwise it MUST build the from `AccountNumber`, then the to `AccountNumber`, then the `Money` amount, then the `Transfer`, and hand it to `TransferService`. It MUST turn `InvalidAccountNumber` into `invalid_account_number`, `InvalidAmount` into `invalid_amount`, `SameAccount` into `same_account`, `UnknownAccount` into `unknown_account` and `InsufficientFunds` into `insufficient_funds`, carry the header hint from a marked row into the rejected `TransferResult`, and go on to the next row. A domain error MUST never leave `ProcessDailyTransfer`.
- **FR-015** (FR-07; DEC-15, DEC-16): each row MUST be applied once, in file order; a rejected row MUST NOT be retried; two equal rows MUST be two transfers.
- **FR-016** (FR-02; DEC-20): `NoTransfers` MUST be raised, after the balances are loaded, when the transfers file has no rows, with the message `the transfers file has no transfers: <path>`.
- **FR-017** (FR-02; DEC-21): when the transfers file has rows and every one is rejected, the run MUST still complete, and `ProcessDailyTransfer` MUST log `All transfers were rejected; check this is the right file.` at warn level after the rows' warn lines.
- **FR-018** (FR-08; DEC-24; page 6 pick 38): `TotalChanged` MUST carry the totals before and after, with the message `the total of all balances changed from <before> to <after>. No output file was written.`, both written with 2 decimal places, and MUST be raised before the writer or the reporter is called.
- **FR-019** (FR-08; DEC-25, DEC-26): the writer MUST be called only after the total check passes, and the reporter only after the output file is written, exactly once per completed run, and never when the run stops.
- **FR-020** (FR-09; DEC-28, DEC-29): `ProcessDailyTransfer` MUST log through the logger it was given, deciding when to log and at which level, and MUST take each text from `LogMessages` (page 6 pick 37), except the all-rejected warning, whose text `DayResult` owns (shared with the report). The texts are (the log format adds the level and timestamp): info `Run started: balances <balances path>, transfers <transfers path>`; info `Line <N> applied: <masked from> -> <masked to> <amount with 2 decimal places>`; warn `Line <N> rejected: <masked from> -> <masked to> <amount as written> <reason code>`; warn `All transfers were rejected; check this is the right file.`; info `Run ended: processed <p>, applied <a>, rejected <r>`, followed, when <r> is above 0, by ` (<code> <count>, ...)` for each reason code that occurred, in DEC-19 order, separated by `, `.
- **FR-021** (FR-09; DEC-28, DEC-29; page 2 picks 11, 12; page 6 pick 37): in a rejected row's warn line, an empty amount MUST be shown as `""`; for a row marked with the wrong number of fields, the fields MUST be taken by position (from, to, amount), fields the row does not have left out with their separator (decided in the run, item 8), and fields after the third not logged. The header hint MUST NOT appear in a log line. Masking MUST be done by `LogMessages`, which builds the text of every log line except the all-rejected warning, whose text `DayResult` owns (shared with the report): every character except the last 4 becomes `*`, and a value of 4 characters or fewer, including an empty value, is `****`.
- **FR-022** (FR-08; DEC-26): `DayResult` MUST hold the `TransferResult`s in file order, the totals before and after, the opening balance of each account by account number (taken before any transfer is applied), the final accounts in load order, and the output path, and MUST NOT format, print or change anything.
- **FR-023** (FR-02, FR-07, FR-08; DEC-30): `ProcessDailyTransfer` MUST NOT create its own readers, writer, repository, reporter or logger; read the clock when a run time is given; write to standard output except through the reporter; parse CSV; check arguments or file existence; print error messages; or set the exit status.

**The output file ([FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output))**

- **FR-024** (FR-08; DEC-27; page 6 pick 39): `FinalBalancesCsvWriter.default_path(run_time)` MUST return `output/final_balances_YYYY-MM-DD_HHMMSS.csv` from the local run time, 24-hour clock, for example `output/final_balances_2026-11-07_143005.csv`.
- **FR-025** (FR-08; DEC-27; page 2 pick 17): writing MUST produce one line per account, `<full account number>,<balance with exactly 2 decimal places>`, in load order, no header, each line, the last included, ending with LF only on every operating system. It MUST create missing folders on the path.
- **FR-026** (FR-08; DEC-25, DEC-27; page 6 pick 40): the writer MUST create the file only if no file exists at that path at the moment it is opened; otherwise, or if the file cannot be created, it MUST raise `OutputNotWritable` with the message `cannot write output file <path>: <reason from the system>`, leaving a file that already existed unchanged. If writing fails partway, it MUST delete the partial file it created before raising. If a missing folder on the path cannot be created, it MUST raise `OutputNotWritable` with the same message, leaving in place any folder it already created (clarified, item 21). It MUST NOT overwrite a file, read the clock or print anything.

**The report ([FR-08](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output))**

- **FR-027** (FR-08; DEC-21, DEC-26): `ReportPrinter` MUST print the report on standard output from a `DayResult`, in five parts in this order, separated by one empty line, with two spaces between the parts of a line and money with exactly 2 decimal places: (1) `Transfers` then, per row, `  Line <N>  applied  <from> -> <to>  <amount>` or `  Line <N>  rejected  <from> -> <to>  <amount as written>  <reason code>`, or for a row with the wrong number of fields `  Line <N>  rejected  malformed_row: <K> fields, expected 3`; (2) `Summary` then `  Processed: <p>`, `  Applied: <a>`, `  Rejected: <r>`, then `    <reason code>: <count>` for each reason that occurred in DEC-19 order, then `  Total before: <total>` and `  Total after: <total>`; (3) only when every row was rejected, `Warning: All transfers were rejected; check this is the right file.`; (4) `Final balances`, then the header row `Account`, `Opening`, `Closing`, then per account in load order its full account number, its opening balance and its closing balance, each line starting with two spaces, each column as wide as its widest value or heading, two spaces between columns, the account number left-aligned and the amounts right-aligned (DEC-26), for example `  Account           Opening  Closing` and `  1111234522226789   100.00    90.00`; (5) `Output file: <path>`.
- **FR-028** (FR-08; DEC-06, DEC-26; page 2 picks 10, 11): in the report, an empty value MUST be shown as `""`; a rejected header-looking row MUST show `: This looks like a header row; files must not have a header.` after its reason code, or `. This looks like a header row; files must not have a header.` after `malformed_row: <K> fields, expected 3`. Account numbers MUST be shown in full.
- **FR-029** (FR-08; DEC-26; page 6 pick 41): `ReportPrinter` MUST show the output path relative to the current folder when the file is in or below the current folder, and otherwise in full (plan P10). It MUST NOT write to standard error or decide when to print.
- **FR-030** (FR-01, FR-02, FR-09; page 2 pick 15; page 6 pick 53): every file path in a message or log line MUST be shown by the same rule as the output path in the report (decided in the run, item 12). The rule MUST be worked out only in `infrastructure/`, by the helper `DisplayPath`: the `Runner` MUST give `ProcessDailyTransfer` the balances and transfers paths in their shown form and the output path in full, and the application classes MUST show the paths they are given, so no `application/` file requires `infrastructure/display_path`.

**The runner ([FR-09](../../docs/solution-design/02-functional-requirements.md#fr-09-the-runner))**

- **FR-031** (FR-09; DEC-22, DEC-23, DEC-27, DEC-28, DEC-30; page 6 pick 42): `Runner` MUST, in order: (1) check the number of arguments and, if it is 1 or 4 or more, print the usage message on standard error with no log line and return 1; (2) resolve the paths: typed paths against the current folder, default paths against the project root; (3) read `LOG_LEVEL` and build the logger on standard error; (4) read the clock once for the run time; (5) take the output path from the third argument, or from `FinalBalancesCsvWriter.default_path` for the run time, resolved against the project root; (6) run the start checks together; (7) build the real readers, writer, repository and reporter; (8) build `ProcessDailyTransfer` with those parts, the logger and the run time, and run it with the three paths (the balances and transfers paths in their shown form, the output path in full; FR-030); (9) return 0, or for a run-stopping error print its message and one error log line and return 1.
- **FR-032** (FR-09; DEC-22): with no arguments, the balances and transfers files MUST be `data/mable_account_balances.csv` and `data/mable_transactions.csv` under the project root; with 2, the typed files and the default output path; with 3, the third argument as the output path, used as given. The usage message MUST be exactly `Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]` and `With no arguments, runs the sample files in data/.` on two lines. `-h` and `--help` MUST count as one argument.
- **FR-033** (FR-09; DEC-23, DEC-25; page 2 pick 18): the start checks MUST check that the balances file exists, that the transfers file exists, and that no file exists at the output path, and MUST report every problem found, in that order, one line each: `Error: file not found: <path>` and `Error: output file already exists: <path>. Delete it or give another output path.`, then one error log line `Run stopped: start checks failed (<reasons>)`, where `<reasons>` lists `file not found` and `output file already exists`, each once and only if it occurred, in that order, separated by `, `. Nothing is read when a start check fails. An existing folder at the output path MUST pass the start check (it fails when written, AC-09.4).
- **FR-034** (FR-09; DEC-25, DEC-28): for each run-stopping error (`InvalidBalancesFile`, `NoTransfers`, `TotalChanged`, `UnreadableFile`, `OutputNotWritable`), `Runner` MUST print `Error: ` followed by the error's message, unchanged, on standard error as plain text, then one error log line from the [run-stopping messages table](#run-stopping-messages), with no account numbers, and return 1. No Ruby stack trace MUST reach the user for these errors. An unexpected error (a bug) MUST NOT be caught (page 9 pick 45).
- **FR-035** (FR-09; DEC-28): the log level MUST be info when `LOG_LEVEL` is `info` in any letter case, and warn otherwise (unset, `warn`, or any other value). The logger MUST use `Logger`'s default format in local time, writing to standard error.
- **FR-036** (FR-09; DEC-25, DEC-26): standard output MUST carry only the report; error messages, the usage message and log lines MUST go to standard error. A stopped run MUST print no report and leave no output file, and an output file that already existed MUST be unchanged.
- **FR-037** (FR-09; DEC-22; page 6): `bin/run` MUST call `Runner` with the arguments and exit with the status it returns, passing no run time and doing nothing else. On Windows it is run as `ruby bin/run`.
- **FR-038** (FR-09; DEC-22, DEC-34; decided in the run, item 14): `data/` MUST hold unchanged copies of `docs/challenge/mable_account_balances.csv` and `docs/challenge/mable_transactions.csv` named the same, and `spec/fixtures/sample/` MUST hold the same copies for the tests; `docs/challenge/` is never edited.

**Scale ([NFR-03](../../docs/solution-design/03-non-functional-requirements.md#nfr-03))**

- **FR-039** (NFR-03; DEC-32): a whole run MUST take time and memory in proportion to the rows in the balances file plus the rows in the transfers file, with no step comparing every row with every other row.
- **FR-040** (NFR-03; DEC-12, DEC-26, DEC-32): the balances file MUST be read in full before any transfer; the transfers file MUST be read one row at a time; one `TransferResult` per row MUST be kept for the report; there MUST be no fixed limit on the number of accounts or transfers.
- **FR-041** (NFR-03; DEC-03): each run MUST start from the balances file and keep nothing between runs.

**Tests ([NFR-06](../../docs/solution-design/03-non-functional-requirements.md#nfr-06))**

- **FR-042** (NFR-06; DEC-34): every rule in this spec MUST be tested once, at the level where it lives: application classes in `spec/application/` (builders, fakes such as readers giving rows from memory, a memory logger and a fixed run time); infrastructure classes in `spec/infrastructure/` (fixture files or a temporary folder); one spec file per class; shared helpers in `spec/support/`.
- **FR-043** (NFR-06; DEC-34): fixture files MUST be used only for the file-level behaviour DEC-34 lists and the end-to-end inputs; copies of the challenge's files MUST be in `spec/fixtures/sample/`.
- **FR-044** (NFR-06; DEC-22, DEC-34, DEC-35; page 9 pick 48): exactly five end-to-end specs in `spec/acceptance/` MUST run `bin/run` as a separate process and check standard output, standard error, the output file and the exit status: the sample files, mixed rejections, all rejected, an invalid balances file, and 1 argument. Apart from the usage run, each passes all three arguments and writes into a temporary folder. The captured standard output and standard error MUST have each CR LF turned into LF before the exact comparison, so the specs pass on Windows as well; the output file MUST be compared byte for byte (clarified, item 22).
- **FR-045** (NFR-06, brief rule 4; decided in the run, item 1): every page 2 scenario of FR-01 to FR-09 MUST be run through `Runner` with real CSV files written into a temporary folder, checking standard output, standard error and the exit status exactly, with `<timestamp>`, `<pid>` and `<reason from the system>` matched as patterns. Where a scenario needs a state that correct code or the operating system cannot produce on demand (AC-08.5, AC-09.1, AC-09.3a), the test is as that scenario states.
- **FR-046** (NFR-06; DEC-24; page 9 picks 46, 47): the total-check failure MUST be tested as AC-08.5 states, split between the `ProcessDailyTransfer` and `Runner` specs.
- **FR-047** (NFR-06; DEC-28, DEC-30): no test MUST depend on the clock or the terminal: tests pass a fixed run time and a memory logger to `ProcessDailyTransfer`, and capture standard output and standard error of `Runner`. No test stubs `Time.now` or `Date.today`.
- **FR-048** (NFR-06; DEC-34, DEC-36): the suite MUST pass in random order, with test names that read as behaviour in documentation format, and SimpleCov MUST measure coverage on every run with no minimum. RuboCop MUST still report zero offences (NFR-05, owned by `001`).

### Run-stopping messages

Exact text, character for character, as on [page 2](../../docs/solution-design/02-functional-requirements.md) and in the [page 9 table](../../docs/solution-design/09-considerations.md#standard-output-standard-error-and-exit-codes). Every one gives standard output (nothing) and exit status 1. `<path>` is shown by the rule in FR-030. The runner prints the plain-text line(s) on standard error, then the log line `E, [<timestamp> #<pid>] ERROR -- : <log text>`.

| Situation | Raised or found by | Standard error, plain text | Log text | Page 2 |
|---|---|---|---|---|
| Wrong number of arguments | `Runner` | `Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]` and `With no arguments, runs the sample files in data/.` | none | AC-09.2 |
| An input file missing | `Runner` (start checks) | `Error: file not found: <path>` | `Run stopped: start checks failed (<reasons>)` | AC-09.3 |
| The output file already exists | `Runner` (start checks) | `Error: output file already exists: <path>. Delete it or give another output path.` | `Run stopped: start checks failed (<reasons>)` | AC-09.3 |
| An input file cannot be opened | `UnreadableFile` | `Error: cannot read file <path>: <reason from the system>` | `Run stopped: cannot read file` | AC-09.3a |
| Invalid balances file | `InvalidBalancesFile` | `Error: the balances file is invalid (<count>):` then each `  Line <N>: <problem>` | `Run stopped: balances file invalid: <count>` | AC-01.4 to AC-01.10 |
| Balances file with no rows | `InvalidBalancesFile` | `Error: the balances file has no rows: <path>` | `Run stopped: balances file invalid: 1 problem` | AC-01.8 |
| Balances file unreadable past a line | `InvalidBalancesFile` (from `UnreadableFile`) | the last problem line `  Line <N>: cannot read <path> from this line. Check for an unclosed quote or characters that are not text.` | `Run stopped: balances file invalid: <count>` | AC-01.9 |
| Transfers file with no rows | `NoTransfers` | `Error: the transfers file has no transfers: <path>` | `Run stopped: transfers file has no transfers` | AC-02.4 |
| Transfers file unreadable past a line | `UnreadableFile` | `Error: cannot read <path> from line <N>. Check for an unclosed quote or characters that are not text.` | `Run stopped: cannot read file` | AC-02.5 |
| Total of all balances changed | `TotalChanged` | `Error: the total of all balances changed from <before> to <after>. No output file was written.` | `Run stopped: total of all balances changed` | AC-08.5 |
| Output file cannot be written | `OutputNotWritable` | `Error: cannot write output file <path>: <reason from the system>` | `Run stopped: cannot write output file` | AC-09.4 |

`<count>` is `1 problem` or `<n> problems` (decided in the run, item 6). The error's own message is the text after `Error: `; the `Runner` adds only the `Error: ` prefix and the log line (decided in the run, item 7). The problem lines inside the balances message use the domain messages of `001` unchanged.

### Key Entities *(include if feature involves data)*

Names and meanings as on [page 6](../../docs/solution-design/06-components.md) and in the [page 10 glossary](../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary).

- **`LoadBalances`** (application): turns balances rows into `Account`s in the repository, or reports every problem. Remembers where each account first appeared.
- **`ProcessDailyTransfer`** (application): runs the day with the parts passed in; writes the output file, prints the report through the reporter, and returns a `DayResult`. Logs each event through the logger, with the text from `LogMessages`, except the all-rejected warning, whose text `DayResult` owns (shared with the report).
- **`LogMessages`** (application): gives the text of each log line of the day's run, except the all-rejected warning, whose text `DayResult` owns (shared with the report), with account values masked; writes nothing itself.
- **`DayResult`** (application): the `TransferResult`s, the totals before and after, the opening balance of each account, the final accounts in load order and the output path.
- **`InvalidBalancesFile`**, **`NoTransfers`**, **`TotalChanged`** (run-stopping errors, application).
- **`BalancesCsvReader`**, **`TransfersCsvReader`** (infrastructure): read a CSV file and give each row with its line number, marking a wrong field count and a header-looking first row.
- **`FinalBalancesCsvWriter`** (infrastructure): `default_path(run_time)`, and writes the output file without ever overwriting one.
- **`ReportPrinter`** (infrastructure): the reporter; prints the report on standard output.
- **`Runner`** (infrastructure): checks the arguments and files, reads the clock once, builds the real parts, runs the day, prints error messages and returns the exit status.
- **`UnreadableFile`**, **`OutputNotWritable`** (run-stopping errors, infrastructure).
- **`bin/run`** (command): the command a user types; calls `Runner`.
- Used from `001`: `AccountNumber`, `Money`, `Account`, `Transfer`, `TransferResult`, `AccountRepository`, `TransferService` and the seven domain errors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (FR-08; DEC-35): the sample files give exactly the closing balances 4820.50, 9974.40, 1550.00, 1725.60 and 48679.50, total 66750.00 before and after, in the report and the output file, with exit status 0 and empty standard error.
- **SC-002** (FR-01, FR-02, FR-07 to FR-09, brief rule 4): 100% of the page 2 scenarios (FR-01 to FR-09) are run through the runner, and each matches standard output, standard error and the exit status exactly.
- **SC-003** (FR-01, FR-02, FR-08, FR-09): every run-stopping message in the tests matches the [run-stopping messages table](#run-stopping-messages) character for character, 11 of 11 rows.
- **SC-004** (FR-09; DEC-25): every stopped run in the tests leaves standard output empty, writes no output file and leaves an existing output file byte for byte unchanged.
- **SC-005** (NFR-06; DEC-34): exactly 5 end-to-end specs, and the suite passes in 3 runs in a row with different random seeds.
- **SC-006** (NFR-06; DEC-28, DEC-30): 0 tests read or stub the clock, and 0 tests depend on the terminal.
- **SC-007** (NFR-03): the design review of the time and space table finds 0 steps whose cost grows faster than the rows in the two files.
- **SC-008** (NFR-05, owned by `001`): the style checker still reports 0 offences.

## Assumptions

- The assumptions in [`design-decisions.md`](../../docs/design-analysis/design-decisions.md#assumptions) hold; in particular the input files are UTF-8 text, the transfers order is the company's intended order, and a day's transfers fit in memory.
- `001-domain` is finished before this spec is built: its classes, members and messages are as in [`specs/001-domain/spec.md`](../001-domain/spec.md).
- The project root is the folder that holds `bin/`; default paths are found from it, wherever the command is run.
- Out of scope, as on [page 4](../../docs/solution-design/04-scope.md#out-of-scope): several companies; storage between runs; retrying rejected transfers or any order other than file order; detecting duplicate transfers; creating accounts; header detection; check-digit validation; rounding or truncating; rollback, database transactions or sagas; streaming or chunking; masking on screen or in the output file; logging to a file or service; named options, a `--force` option or a help option; a money gem; a coverage threshold.
- The README, the coverage figure in it, CI and Docker are `003-delivery`.

## Decided in the run

Small gaps decided while writing this spec, consistent with `design-decisions.md`. Each is for the developer's review.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| 1 | Runner scenarios run `Runner` in the same process with a temporary folder as the current folder, write the scenario's CSV files into it (not fixture files), and pass `output/final_balances_2026-11-07_143005.csv` as the third argument | Brief rule 4, DEC-30, DEC-34, NFR-06 | The brief asks for every page 2 scenario through the runner with real CSV files and exact streams; this gives page 2's exact output, file paths and output line without reading or stubbing the clock (DEC-30), keeps fixture files for file-level behaviour only and the end-to-end runs at five (DEC-34). The domain rules stay unit-tested once in `001`; these specs check what the runner shows | Stubbing the clock (rejected by DEC-30); a fixture file and an end-to-end run per scenario (rejected by DEC-34); checking only parts of each stream |
| 2 | The five end-to-end runs use AC-08.1 (sample files), AC-08.2 (mixed rejections), AC-02.3 (all rejected: header only), AC-01.4 (invalid balances) and AC-09.2 with 1 argument; each runs in a temporary folder as the current folder, with the default output name as the third argument | DEC-34, NFR-06, page 9 pick 48 | They are the page 2 criteria that print every stream in full for each kind DEC-34 names; the default name as the third argument keeps page 2's exact `Output file:` line | Other criteria; running from the project root (writes into the project's `output/`) |
| 3 | AC-09.1 is checked in the `Runner` spec with a stand-in `ProcessDailyTransfer` that records the run time and paths; AC-08.4's `../bin/run` from `docs` is reproduced by a runner scenario run from a subfolder with `../` paths, whose output file is outside that subfolder and shown in full, and a file elsewhere by an output path in a second temporary folder | DEC-22, DEC-26, page 9 picks 46 and 48 | A no-argument run would write into the project's `output/` under a time-based name; the stand-in is the same technique page 9 uses for the total check | Writing into the project's `output/` during tests; stubbing the clock |
| 4 | AC-09.7 is checked by `default_path` for two run times one second apart, and by two runner runs on the same files giving the same report (apart from the output line) and the same output file | DEC-03, DEC-27 | Proves both halves without a real one-second wait or a clock stub | Sleeping one second between two real runs |
| 5 | AC-08.3's "same format as the balances file" is also checked by behaviour: the AC-08.2 output file, read back as a balances file, loads the three accounts with their final balances | DEC-27 | DEC-27 says the output exists so the next day's run can use it; reading it back proves that directly | Comparing the format by eye only |
| 6 | The problem count is singular for one problem: `(1 problem)` in the `Error:` line and `1 problem` in the log line | DEC-12, page 2 AC-01.8 | Page 2 already writes `1 problem` in the log line; the same word form in both places | `(1 problems)` |
| 7 | Each run-stopping error's message is the text after `Error: `; the `Runner` adds only `Error: ` and the log line, and never rewrites the message. Which class holds the log text is the plan's choice | Brief rule 4, DEC-25, DEC-28 | One owner per message, as the domain owns its messages | The `Runner` building every message from the error's data |
| 8 | A transfers row with the wrong number of fields: in the log, a missing field is left out together with its separator (1 field gives `Line <N> rejected: <masked from> malformed_row`); in the report, the pattern `malformed_row: <K> fields, expected 3` is used for every count, including 1 | DEC-28, page 2 pick 12, FR-08 layout | Page 2 says missing fields are left out and gives one pattern for the report | A dangling `->`; a singular `1 field` (a second wording not on page 2) |
| 9 | Page 2 criteria that give only part of a file are completed as stated in each scenario: AC-01.3 line 4 `12345,50.00`; AC-01.6 line 1 `1212343433335665,50.00`; AC-01.7 header followed by `balances.csv`; AC-01.9 lines 1, 2, 4 to 7; AC-01.2 compared with the plain file; AC-08.3 folders `out/new/` | FR-01, FR-08 | Each completion is the smallest file that shows the criterion's point; it adds no behaviour | Other contents |
| 10 | Tests match `<reason from the system>` as any non-empty text after the fixed part | DEC-23, DEC-25 | The system's wording differs by operating system | Comparing one system's wording |
| 11 | The test for an input file that exists but cannot be opened uses a way that works on every operating system the suite runs on (for example a folder at the input path, which exists but cannot be read as a file); the plan picks it | DEC-23, NFR-06 | Removing read permission does not work on Windows, or when the tests run as an administrator | A test that runs only on some systems |
| 12 | One rule shows every path the user sees (report, messages, log lines): relative to the current folder, or in full outside it; the plan picks where that rule lives, and `ReportPrinter` uses it for the output line | Page 2 pick 15, page 6 pick 41, DEC-26 | One rule for every path, as page 2 says | Showing paths as typed in messages |
| 13 | `LOG_LEVEL` is compared in any letter case, without trimming spaces; any other value, including ` info `, falls back to warn | DEC-28 | DEC-28 accepts only `warn` and `info` in any letter case | Trimming the value |
| 14 | `002` creates `data/` with copies of the two sample files, and `spec/fixtures/sample/` with the same copies | DEC-22, DEC-34 | `bin/run` with no arguments needs `data/`; the end-to-end spec needs the copies; `003` adds no test data beyond these | Reading `docs/challenge/` directly (rejected by DEC-22) |
| 15 | The start check for the output path fails only when a file exists there; an existing folder passes it and fails when written | DEC-25, page 2 pick 14 | Page 2 says a folder gives "cannot write output file", not "already exists" | Failing a folder at the start check |
| 16 | A transfers file whose first row already cannot be read stops with `UnreadableFile`, not `NoTransfers` | DEC-04, DEC-20 | The file has a row the library cannot read, so it is not empty; the reader raises before any row is given | Treating it as an empty file |
| 17 | A single-row example is line 1 of `transfers.csv`, its only row, and Templates A and R give the rest of standard output; derived lines are marked **(derived)** | DEC-21, DEC-26, DEC-29 | The brief asks for every stream in every scenario; deriving from the FR-08 layout adds no behaviour; matches `001` | Leaving streams unstated |
| 18 | Tabs around a value are trimmed like spaces; spaces and tabs inside a value are kept (clarification 1) | DEC-04, DEC-05, FR-01, FR-02 | DEC-05 already treats spaces and tabs alike as blank; trimming only spaces would make `<tab>100.00` an invalid amount for a character the user cannot see | Trimming spaces only; removing whitespace inside a value |
| 19 | The duplicate known gap covers any first copy that is not added because of its own problem: an invalid or negative balance, or the wrong number of fields (clarification 2) | DEC-12, page 6 known gap, page 6 pick 30 | Page 6 states the gap for "the invalid row" in general; the account is added only from a row with no problem, so every such row leaves the same gap; the run stops either way | Remembering numbers from rows that were not added (rejected by page 6 pick 30) |
| 20 | At info level, a run stopped after the start checks keeps the `Run started` line and any row lines already logged, and logs no `Run ended`; a run stopped by the arguments or start checks logs no info line (clarification 3) | DEC-28, FR-013 order, page 2 AC-09.5 | `Run ended` reports a completed run's counts; `Run started` is logged by `ProcessDailyTransfer`, which the runner builds only after the start checks pass | Logging `Run ended` with partial counts for a stopped run |
| 21 | A missing folder on the output path that cannot be created raises `OutputNotWritable` with the AC-09.4 message; folders already created are left in place (clarification 4) | DEC-25, DEC-27, page 2 pick 14 | It is a case of "the output file cannot be written"; DEC-27 deletes only a partial file, and an empty folder holds no balances | A new message; removing the created folders |
| 22 | The end-to-end specs turn CR LF into LF in the captured standard output and standard error before comparing; the output file is compared byte for byte (clarification 5) | DEC-34, NFR-04, page 2 pick 17 | Ruby on Windows writes CR LF to a pipe, so a byte comparison of the streams would fail on the developer's machine; page 2 fixes LF only for the output file | Switching standard output to binary mode in the program (new behaviour); comparing the streams only on Linux |
| 23 | Unless a scenario says otherwise, `transfers.csv` holds the one row `1111234522226789,1212343433335665,10.00`, AC-01.1's file; a scenario that needs a different transfers file, a missing one or a folder of that name says so | FR-01, FR-09, DEC-23 | Every runner scenario runs `bin/run balances.csv transfers.csv`, and the start checks stop the run when `transfers.csv` does not exist (FR-033), so the FR-01 and AC-09.3a scenarios, which say nothing about it, need a file that exists; the smallest valid file adds no behaviour | Leaving the file unstated (the run would stop at the start checks with `file not found`) |
