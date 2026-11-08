# Implementation Plan: File reading, the day's run and the runner

**Branch**: `002-file-runner` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-file-runner/spec.md`. The `/speckit-plan` input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#speckit-plan-002-file-runner).

## Summary

Build, on the finished domain of [`001-domain`](../001-domain/plan.md), the application layer in `lib/application/` (`LoadBalances`, `ProcessDailyTransfer`, `DayResult`, and the run-stopping errors `InvalidBalancesFile`, `NoTransfers`, `TotalChanged`), the infrastructure layer in `lib/infrastructure/` (`BalancesCsvReader`, `TransfersCsvReader`, `FinalBalancesCsvWriter` with `default_path`, `ReportPrinter`, `Runner`, and the run-stopping errors `UnreadableFile`, `OutputNotWritable`), and the command `bin/run`, with `data/` holding the two sample files ([DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)).

The `Runner` checks the arguments, shows every path once by one rule, reads `LOG_LEVEL` and the clock once, runs the start checks together, builds the real parts and hands them to `ProcessDailyTransfer` ([DEC-30](../../docs/design-analysis/design-decisions.md#dec-30)). `ProcessDailyTransfer` loads the balances through `LoadBalances`, turns every transfers row into a `TransferResult` in file order, checks the total, writes the output file and then prints the report through the reporter ([DEC-15](../../docs/design-analysis/design-decisions.md#dec-15), [DEC-24](../../docs/design-analysis/design-decisions.md#dec-24), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26)). Every run-stopping error reaches the `Runner`, which prints `Error: ` and the error's own message, logs one line and returns 1 ([DEC-25](../../docs/design-analysis/design-decisions.md#dec-25)).

Tests come first in every phase: unit specs for the application classes with fakes and a fixed run time, integration specs for the infrastructure classes with fixture files or a temporary folder, every page 2 scenario run through `Runner` with real CSV files, and exactly five end-to-end runs of `bin/run` ([DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), brief rule 4).

Owns: FR-01, FR-02, FR-07, FR-08, FR-09, NFR-03, NFR-06.

## Technical Context

Every choice below is already made in `design-decisions.md`, on [page 5](../../docs/solution-design/05-high-level-design.md) or in `001`'s plan; nothing is added.

**Language/Version**: Ruby 3.4.12, as pinned in `.ruby-version` by `001` (DEC-01; `001` plan D1).

**Primary Dependencies**: runtime: the Ruby standard library only. This spec uses `csv` (reading), `bigdecimal` (through `Money`), `logger`, `fileutils` (creating missing folders), `pathname` (showing paths) and `open3` and `rbconfig` in the end-to-end specs; `csv`, `bigdecimal` and `logger` are already in the `Gemfile` (DEC-01). Development and test: `rspec`, `simplecov`, `rubocop`, `rubocop-rspec`, already in the `Gemfile` from `001` (DEC-36). No other gem, framework or logging library.

**Storage**: none between runs (DEC-03). Input: two CSV files. Output: one new CSV file per completed run ([DEC-27](../../docs/design-analysis/design-decisions.md#dec-27)).

**Testing**: RSpec, random order with the seed printed, documentation format, SimpleCov on every run with no minimum, as set up by `001` (DEC-34, DEC-36). Application specs in `spec/application/` (fake readers giving rows from memory, a fake reporter, a memory logger, a fixed run time); infrastructure specs in `spec/infrastructure/` (fixture files or a temporary folder); the page 2 scenarios in the `Runner` spec with CSV files written into a temporary folder; five end-to-end specs in `spec/acceptance/` running `bin/run` as a separate process. No test reads or stubs the clock (FR-047).

**Target Platform**: any machine with Ruby 3.4 (Linux in CI and Docker, Windows and macOS by hand). The output file uses LF only on every system (page 10 pick 17); the end-to-end specs turn CR LF into LF in the captured streams so they also pass on Windows (spec clarification 5).

**Project Type**: command-line program; this spec builds its application and infrastructure layers and the command.

**Performance Goals**: growth rates only (NFR-03): a whole run is O(m + n) in time and space for m accounts and n transfer rows; the transfers file is read one row at a time; one `TransferResult` per row is kept for the report ([page 9 time and space](../../docs/solution-design/09-considerations.md#time-and-space)). No timing test and no large test file.

**Constraints**: RuboCop default settings plus `rubocop-rspec`, zero offences, so at most 10 lines per method, 5 parameters per method (keywords counted) and 100 lines per class (NFR-05, owned by `001`; research R8). Standard output carries only the report (DEC-26). Exact messages are copied from the spec's [run-stopping messages table](spec.md#run-stopping-messages) and the domain's messages from `001`'s [contract](../001-domain/contracts/domain-api.md), never rewritten.

**Scale/Scope**: one company's accounts and one day's transfers (DEC-02, DEC-32); 4 application files, 9 infrastructure files, `bin/run`, 11 spec files, 5 end-to-end specs, and the fixture files DEC-34 lists.

## Constitution Check

*GATE: checked before Phase 0 and again after Phase 1. Against [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) v1.0.0.*

| Principle | How this plan meets it | Pre-design | Post-design |
|---|---|---|---|
| I. Domain models encapsulate their own rules | No domain rule is added or repeated: `LoadBalances` and `ProcessDailyTransfer` build `AccountNumber`, `Money`, `Transfer` and `Account` and turn their errors into problems or reason codes (FR-011, FR-014). The duplicate text comes from `DuplicateAccount.new(number).message` (`001` plan D21). Plain names from page 6, the three infrastructure helpers `Row`, `CsvRows` and `DisplayPath` included (page 6 picks 52 and 53); each holds one rule (P2, P3, P10). `Hash`, `Array` and `Data` used directly. | PASS | PASS ([data-model.md](data-model.md) lists one home per rule) |
| II. Separation of concerns | CSV only in `CsvRows` and the two readers; the screen only in `ReportPrinter` and `Runner`; the clock only in `Runner` (and `ProcessDailyTransfer`'s default argument); arguments, `LOG_LEVEL` and file existence only in `Runner`. Readers, writer, repository, reporter, logger and run time are passed in to `ProcessDailyTransfer` (DEC-30). Row-shape checks stay in the readers (DEC-06, page 6). | PASS | PASS |
| III. Short, readable methods | RuboCop defaults with `rubocop-rspec`, zero offences; each class has a one-line comment saying what it is, and no comment explains the design (DEC-30, DEC-36; `001` plan D16). The six parts of `ProcessDailyTransfer` are passed as named keywords collected in one `**parts` argument so the default parameter limit holds without a new class or a changed setting (P6, research R8). | PASS | PASS |
| IV. Tests first (non-negotiable) | Every task phase writes its specs first and sees them fail, then writes the code; each phase ends with every spec passing in random order and RuboCop clean. One rule tested once, where it lives; fixture files only for file-level behaviour; every page 2 scenario through `Runner`; exactly five end-to-end runs; every edge case in the spec has a planned test citing its DEC ID (DEC-34). | PASS | PASS |
| V. Check everything before any balance changes | All balances problems are found before any transfer (`LoadBalances` reads every row, DEC-12); each transfer goes through `TransferService` (`001`, DEC-18); the total is checked before the writer is called; a stopped run writes no file and the writer deletes its own partial file (DEC-24, DEC-25, DEC-27). | PASS | PASS |
| VI. Money exact to the cent | Totals are added with `Money#+` from `AccountRepository#all` (page 10 pick 38); every amount and balance shown or written uses `Money#to_s`; nothing parses money outside `Money` (DEC-09). | PASS | PASS |
| VII. No over-engineering | Only the components page 6 names, plus three small helpers that each hold one rule (P2, P3, P10). No namespace module, no base error class, no extra gems, no options beyond 0, 2 or 3 positional arguments. | PASS | PASS |
| VIII. Standard output for results only | Only `ReportPrinter` writes to standard output, once per completed run, after the output file is written; error messages, the usage message and log lines go to standard error; exit status 0 or 1 (DEC-23, DEC-25, DEC-26, DEC-28). | PASS | PASS |
| Technology constraints | Ruby 3.4.12; standard library only at run time; `Logger` for logging; the four development gems; nothing added. | PASS | PASS |
| Development workflow | Tasks only through `/speckit-tasks`; tests first; FR, NFR and DEC IDs cited; every compared string copied from the spec. | PASS | PASS |

No violation, so Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/002-file-runner/
├── spec.md                     # /speckit-specify and /speckit-clarify output
├── plan.md                     # This file (/speckit-plan output)
├── research.md                 # Phase 0 output
├── data-model.md               # Phase 1 output
├── quickstart.md               # Phase 1 output
├── contracts/
│   ├── components-api.md       # Phase 1 output: the public members of this spec's classes
│   └── command-line.md         # Phase 1 output: bin/run's arguments, streams, files and exit status
├── checklists/
│   └── requirements.md         # /speckit-specify output
└── tasks.md                    # /speckit-tasks output
```

### Source Code (repository root)

Added by this spec, next to what `001` created ([`001` plan](../001-domain/plan.md#source-code-repository-root)). The layout follows [page 5](../../docs/solution-design/05-high-level-design.md#the-three-layers) and [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34).

```text
bin/
└── run                                  # the command (executable)

data/
├── mable_account_balances.csv           # copy of docs/challenge/, unchanged
└── mable_transactions.csv               # copy of docs/challenge/, unchanged

lib/
├── domain/                              # from 001, unchanged
├── application/
│   ├── errors.rb                        # InvalidBalancesFile, NoTransfers, TotalChanged
│   ├── load_balances.rb                 # LoadBalances
│   ├── day_result.rb                    # DayResult
│   └── process_daily_transfer.rb        # ProcessDailyTransfer
└── infrastructure/
    ├── errors.rb                        # UnreadableFile, OutputNotWritable
    ├── row.rb                           # Row (P2)
    ├── csv_rows.rb                      # CsvRows (P3)
    ├── balances_csv_reader.rb           # BalancesCsvReader
    ├── transfers_csv_reader.rb          # TransfersCsvReader
    ├── display_path.rb                  # DisplayPath (P10)
    ├── final_balances_csv_writer.rb     # FinalBalancesCsvWriter
    ├── report_printer.rb                # ReportPrinter
    └── runner.rb                        # Runner

spec/
├── spec_helper.rb                       # from 001, unchanged
├── support/
│   ├── builders.rb                      # from 001; this spec adds row builders
│   ├── fakes.rb                         # FakeReader, FakeReporter, ChangingTotalRepository, memory logger
│   ├── files.rb                         # temporary folders and written files
│   ├── runs.rb                          # running Runner in a folder; stream patterns
│   └── report_templates.rb              # Templates A and R of the spec
├── application/
│   ├── load_balances_spec.rb
│   ├── day_result_spec.rb
│   └── process_daily_transfer_spec.rb
├── infrastructure/
│   ├── row_spec.rb
│   ├── csv_rows_spec.rb
│   ├── balances_csv_reader_spec.rb
│   ├── transfers_csv_reader_spec.rb
│   ├── display_path_spec.rb
│   ├── final_balances_csv_writer_spec.rb
│   ├── report_printer_spec.rb
│   └── runner_spec.rb                   # the Runner's own behaviour and every page 2 scenario (P18)
├── acceptance/                          # exactly five end-to-end specs (P19)
│   ├── runner_run_sample_files_spec.rb
│   ├── runner_run_mixed_rejections_spec.rb
│   ├── runner_run_all_rejected_spec.rb
│   ├── runner_run_invalid_balances_spec.rb
│   └── runner_run_wrong_arguments_spec.rb
└── fixtures/                            # P20
    ├── sample/                          # copies of the two challenge files
    ├── reading/                         # blank lines, header row, byte-order mark, unclosed quote, empty, wrong field count
    ├── leading_zeros/                   # an account with leading zeros in both files
    └── acceptance/                      # the inputs of the mixed, all-rejected and invalid-balances runs
```

**Structure Decision**: a single Ruby project, code under `lib/` in the three layer folders of DEC-30 and specs under `spec/` mirroring the code, one spec file per class (DEC-34). The errors hold only their messages and stop reasons, so each `errors.rb` has no spec file of its own; each error, its exact message and its stop reason are tested in the spec of the class that raises it and in the `Runner` spec (as `001` plan D3). `DayResult` and `Row` are `Data` values with a few members of their own, so each has a short spec.

## Design overview

The public members, their arguments and the exact messages are in [contracts/components-api.md](contracts/components-api.md); the command's behaviour is in [contracts/command-line.md](contracts/command-line.md); fields, rules and relationships are in [data-model.md](data-model.md); the reasoning for each technical choice is in [research.md](research.md). Every domain member used here is the one in `001`'s [contract](../001-domain/contracts/domain-api.md).

- **Reading** (FR-001 to FR-006): `BalancesCsvReader#each_row(path)` and `TransfersCsvReader#each_row(path)` yield one `Row` at a time through `CsvRows`, which opens the file as `r:bom|utf-8` with Ruby's CSV library, skips blank lines, trims spaces and tabs around each value, gives each row its physical line number (the line where it starts), marks the expected number of fields (2 or 3) and the header hint on a header-looking first data row, and raises `UnreadableFile` for a file that cannot be opened or a line it cannot read past (research R1, R2).
- **Loading the balances** (FR-007 to FR-011): `LoadBalances.new(reader, repository).call(path)` checks every row in the order of page 6 and raises `InvalidBalancesFile` with every problem, or the no-rows problem (research R4).
- **Running the day** (FR-012 to FR-023): `ProcessDailyTransfer.new(run_time: Time.now, **parts).call(balances_path, transfers_path, output_path = nil)` logs the start, loads the balances, takes the total before, turns each row into a `TransferResult` (logging each), raises `NoTransfers` or logs the all-rejected warning, checks the total, writes the output file, prints the report through the reporter, logs the end and returns the `DayResult` (research R5).
- **The output file** (FR-024 to FR-026): `FinalBalancesCsvWriter.default_path(run_time)` and `#write(accounts, path)`, which creates missing folders, creates the file only if none exists at that moment, writes one LF-ended line per account, and deletes its own partial file on failure (research R6).
- **The report** (FR-027 to FR-030): `ReportPrinter.new(output:, current_folder:).print(day_result)` prints the five parts; the output line shows the path by `DisplayPath` (research R3).
- **The runner** (FR-031 to FR-037): `Runner.new(stdout:, stderr:, env:).run(arguments)` returns 0 or 1; `bin/run` exits with it (research R7).

Each message has one owner: the domain errors own their text (`001`); each run-stopping error builds its own message and its stop reason, the text after `Run stopped: ` in the error log line (P8); the `Runner` adds only `Error: ` and the log line, and owns the usage message and the start-check messages, which have no error class (spec item 7).

## Test approach

- **Tests first.** Each task phase writes its spec examples, runs them and sees them fail (a missing class or a failed expectation), then writes the code until the phase's specs pass in random order and `bundle exec rubocop` reports zero offences. Where a phase's scenario specs check behaviour that an earlier phase already built and tested in a unit spec, the phase says so; a scenario that fails is fixed test-first in the class that owns the behaviour (P24).
- **One rule, one place.** Each rule is tested in the spec of the class that owns it (DEC-34): the reading rules once in `csv_rows_spec.rb`, the field counts in the reader specs, every balances problem in `load_balances_spec.rb`, the reason mapping, masking and log lines in `process_daily_transfer_spec.rb`, the path rule in `display_path_spec.rb`, the report layout in `report_printer_spec.rb`, the writer's rules in `final_balances_csv_writer_spec.rb`, and the runner's own steps in `runner_spec.rb`. Domain rules are not tested again (`001`).
- **Page 2 scenarios through the runner** (brief rule 4, FR-045). In `runner_spec.rb`, grouped by FR, each scenario writes its CSV files into a temporary folder used as the current folder, runs `Runner` with `StringIO` streams and the third argument `output/final_balances_2026-11-07_143005.csv`, and checks standard output, standard error and the exit status in three separate examples; `<timestamp>`, `<pid>` and `<reason from the system>` are matched as patterns (spec items 1 and 10).
- **End to end** (FR-044). Five specs run `ruby bin/run` as a separate process with `Open3.capture3` in a temporary folder, with `LOG_LEVEL` removed from the environment, turn CR LF into LF in the captured streams, compare standard output, standard error and the exit status, and compare the output file byte for byte (P25).
- **RuboCop's RSpec defaults shape the specs**, as in `001` (`001` plan D17): one expectation per example, examples of at most 5 lines, at most 3 levels of nesting; a scenario's three streams are three examples sharing one memoised run.
- **No clock and no terminal** (FR-047): `ProcessDailyTransfer` gets a fixed `Time.new(2026, 11, 7, 14, 30, 5)` and a memory logger; `Runner` gets `StringIO` streams and an environment `Hash`; nothing stubs `Time.now` or `Date.today`. The two places that need a state correct code cannot reach (AC-08.5 and AC-09.1) stub `ProcessDailyTransfer.new` with a stand-in, as page 9 pick 46 sets out.

## Decided in the run

Names and details that page 6 and the page 10 glossary leave open, and small technical gaps, decided consistently with `design-decisions.md`. Each is for the developer's review. Reasons and rejected options are in [research.md](research.md) where they need more than a line.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| P1 | Every class and error is a top-level constant with its page 6 name, in the files listed under Source Code; each code file loads what it uses with `require_relative`, and specs require `'application/<file>'` or `'infrastructure/<file>'` | DEC-30, `001` plan D2, D13 | Same as the domain: the names stay exactly as on page 6 | A namespace module |
| P2 | A row given by a reader is a `Row`, a `Data` value in `lib/infrastructure/row.rb` with `line_number`, `fields` (trimmed text), `expected_size` and `header_hint` (nil unless marked), and the predicate `wrong_field_count?` (`fields.size != expected_size`) | DEC-04, DEC-06, DEC-07, FR-003, FR-004, page 6 pick 52 | Page 5 says any reader gives "the same rows"; one small value carries the row, its line and both reader marks to `LoadBalances` and `ProcessDailyTransfer` | Arrays of fields with the line number passed beside them; a flag for the wrong count separate from the counts |
| P3 | The reading rules shared by both readers live once in `CsvRows` (`lib/infrastructure/csv_rows.rb`), an `Enumerable` built with a path and the expected number of fields; it owns the header hint text as `CsvRows::HEADER_HINT` | DEC-04 to DEC-07, DEC-32, FR-001 to FR-005, page 6 pick 52, constitution I and VII | The two readers differ only in the number of fields; one owner for the reading rules means one test of each (DEC-34) and no base class (DEC-30) | A base reader class (ruled out by DEC-30); a mixin (the rules would be tested through both readers); copying the rules into both readers |
| P4 | Both readers have `each_row(path) { \|row\| ... }` and a constant `FIELD_COUNT` (2 and 3); both read through `CsvRows`, one row at a time. "Read in full" for the balances file means every row is read and checked before any transfer, which `LoadBalances` does | DEC-32, FR-006, NFR-03 | The row-by-row read is what lets the rows before an unreadable line be given first (DEC-04); reading the balances text into memory first would add nothing that can be tested | `rows(path)` returning an `Array` (the rows before an unreadable line would be lost); reading the balances file into a string first |
| P5 | `LoadBalances.new(reader, repository)` and `LoadBalances#call(path)`, which returns nil after filling the repository | page 6 `LoadBalances`, FR-007 | The class is named for its one action; `call` is Ruby's usual name for it, and `load` would hide `Kernel#load` | `load`, `run` |
| P6 | `ProcessDailyTransfer.new(run_time: Time.now, **parts)`, where `parts` must hold exactly `balances_reader:`, `transfers_reader:`, `writer:`, `repository:`, `reporter:` and `logger:` (a missing one raises `KeyError` when built); `ProcessDailyTransfer#call(balances_path, transfers_path, output_path = nil)` returns the `DayResult` | DEC-30, FR-012, page 6 picks 34, 35 | RuboCop's default `Metrics/ParameterLists` allows 5 parameters and counts keywords, and DEC-36 keeps the defaults; collecting the six named parts keeps every part passed in by name at the call site, with no new class | Seven keyword parameters (an offence); a parts value class (a DTO, ruled out by DEC-30); changing the RuboCop setting |
| P7 | `DayResult` is a `Data` value with `results`, `total_before`, `total_after`, `accounts` and `output_path`, and the read-only members `processed_count`, `applied_count`, `rejected_count`, `rejected_counts` (reason code to count, in `TransferResult::REASON_CODES` order, only the codes that occurred) and `all_rejected?`; it owns the warning text as `DayResult::ALL_REJECTED_WARNING` | DEC-19, DEC-21, DEC-26, FR-022 | The report and the run-end log line count the same results; counting is a question about the day, not formatting, so it belongs with the day's data | Counting in `ReportPrinter` and again in `ProcessDailyTransfer` (two copies) |
| P8 | The run-stopping errors are direct subclasses of `StandardError`, in `lib/application/errors.rb` and `lib/infrastructure/errors.rb`; each builds its own message and has `stop_reason`, the text after `Run stopped: ` in its error log line. Constructors: `InvalidBalancesFile.new(problems)` and `InvalidBalancesFile.no_rows(path)`; `NoTransfers.new(path)`; `TotalChanged.new(before, after)`; `UnreadableFile.cannot_open(path, error)` and `UnreadableFile.at_line(path, line_number)` (with `line_problem` for the balances problem line); `OutputNotWritable.new(path, error)` | DEC-25, DEC-28, DEC-30, spec item 7, `001` plan D3, D21 | One owner for each message and its log text, next to each other; the `Runner` only adds `Error: ` and `Run stopped: ` | A table of log texts in the `Runner` (a second place that must know every error); a base error class (DEC-30) |
| P9 | `<reason from the system>` is the error's message up to Ruby's ` @ ` call details, for example `Permission denied` from `Permission denied @ rb_sysopen - balances.csv` | DEC-23, DEC-25, spec item 10 | The system's description is what helps the user; Ruby's call details repeat the path in another form | The full Ruby message; a fixed text of our own |
| P10 | One rule shows every path the user sees, in `DisplayPath.of(path, folder = Dir.pwd)` (`lib/infrastructure/display_path.rb`): the path relative to the current folder when the file is in it or below it; otherwise the full path | DEC-26, page 2 pick 15, page 6 pick 53, spec items 3 and 12, FR-029, FR-030 | This is DEC-26's rule as written: page 2 shows `output/...` from the project root, the full path from `docs` and `/tmp/day1.csv` in full, and it is the same everywhere. The spec's subfolder and second-temporary-folder cases (spec item 3) both name a file outside the current folder, so both are shown in full | Showing a file in another folder of the parent relative, with `..` steps (DEC-26 shows a file outside the run folder in full); showing paths as typed (rejected by DEC-26) |
| P11 | The `Runner` resolves each path (typed against the current folder, defaults against the project root) into a real, absolute path, which the start checks use. It gives `ProcessDailyTransfer` the balances and transfers paths in their shown form, `DisplayPath.of(path)`, and the output path in full, so `DayResult.output_path` holds the full path. A shown path opens the same file from the current folder. The application classes show the paths they are given (`InvalidBalancesFile.no_rows`, `NoTransfers`, the `Run started` line) and never call `DisplayPath`; the `Runner`'s start-check lines, the infrastructure errors' messages (`UnreadableFile`, `OutputNotWritable`) and `ReportPrinter`'s output line use `DisplayPath.of` | FR-030, FR-031, spec item 12, page 2 pick 15, page 6 picks 41 and 53 | No `application/` file requires `infrastructure/display_path` (page 6 pick 53); `DisplayPath` stays the one owner of the rule (page 2 pick 15); `DayResult` keeps the full output path and `ReportPrinter` is the only component that shows it in the report (page 6 pick 41) | Passing only real paths on and building the shown form in the application errors and `ProcessDailyTransfer` (an application class depending on infrastructure, rejected by page 6 pick 53); turning the output path into its shown form in the `Runner` (page 6 pick 41); each class holding its own copy of the rule |
| P12 | `Runner.new(stdout: $stdout, stderr: $stderr, env: ENV)` and `Runner#run(arguments)`, returning 0 or 1; the project root is the folder above `lib/` | DEC-22, DEC-28, page 6 pick 42, FR-031, FR-047 | Streams and environment passed in let every runner test capture them without touching the terminal | Reading `$stdout` and `ENV` inside the methods |
| P13 | `FinalBalancesCsvWriter.new` takes nothing; `#write(accounts, path)` creates missing folders with `FileUtils.mkdir_p`, opens the file with `File::WRONLY \| File::CREAT \| File::EXCL \| File::BINARY`, writes one `<account number>,<balance>\n` line per account as it goes, and on a `SystemCallError` or `IOError` deletes the file only if it created it, then raises `OutputNotWritable` | DEC-25, DEC-27, FR-025, FR-026, page 6 pick 40 | Exclusive create is the no-overwrite check at the moment of opening; binary mode keeps LF on Windows; line-by-line writing is O(1) extra space (page 9) | Checking `File.exist?` then opening (a gap between the two); writing with the operating system's line ending |
| P14 | `ReportPrinter.new(output: $stdout, current_folder: Dir.pwd)` and `ReportPrinter#print(day_result)` | DEC-26, page 6 pick 41, FR-027 to FR-029 | The stream and the folder passed in let the spec check the report and every path case without a terminal or a real folder | Reading `$stdout` and `Dir.pwd` inside the method |
| P15 | An applied amount is shown, in the report and the info log line, as `Money.amount(text).to_s`; a rejected row's values are shown as written, with an empty value as `""` | DEC-09, DEC-26, page 2 pick 11, FR-020, FR-027, FR-028 | `TransferResult` keeps the values as written (`001`); the domain owns the 2-decimal form | Storing the formatted amount in the result |
| P16 | The logger is `Logger.new(stderr, level:)` with `Logger`'s default formatter; the level is `Logger::INFO` when `env['LOG_LEVEL']` equals `info` ignoring case (`casecmp?`), and `Logger::WARN` otherwise | DEC-28, FR-035, spec item 13 | The default format is the one page 2 shows | A custom formatter |
| P17 | Test helpers: `spec/support/fakes.rb` (`FakeReader`, `FakeReporter`, `ChangingTotalRepository`, `memory_logger` and `log_lines`), `spec/support/files.rb` (`in_temp_folder`, `write_file`, `fixture_path`), `spec/support/runs.rb` (`run_runner`, `run_scenario` with its `read:` option for reading any path in the temporary folder before it is removed, `stream_pattern`, `run_command`), `spec/support/report_templates.rb` (`template_a`, `template_r`), and row builders `balances_row` and `transfers_row` added to `spec/support/builders.rb` | DEC-34, research R9 | Small helpers keep each example to its point and the scenarios close to page 2 | Repeating set-up in every example |
| P18 | The page 2 scenarios run through the runner live in `spec/infrastructure/runner_spec.rb`, grouped by FR, next to the `Runner`'s own examples | DEC-34, FR-042, FR-045 | DEC-34 sets one spec file per class; these specs test what the `Runner` shows | A separate scenarios folder (not in DEC-34's layout); one file per FR for the same class |
| P19 | The five end-to-end specs are `RSpec.describe Runner, '#run'` in `spec/acceptance/runner_run_<case>_spec.rb`, each with one inner `describe 'with <case>'`: `sample files`, `mixed rejections`, `all rejected`, `invalid balances`, `wrong arguments` | DEC-34, FR-044, NFR-05 | RuboCop's default `RSpec/DescribeClass`, `RSpec/DescribeMethod` (the second argument must start with `#` or `.`) and `RSpec/SpecFilePathFormat` (`runner*run*_spec.rb`) then pass together with no setting changed; the command they run ends in `Runner#run`; the case is the inner group, which none of those cops checks | A string description such as `'bin/run'`, or a free-text second argument such as `'sample files'` (offences under the default settings) |
| P20 | Fixture files hold only the cases DEC-34 lists and the end-to-end inputs; cases that depend on exact bytes (Windows line endings, no final newline, tabs, a value over several lines, bytes that are not UTF-8) are written by the test into a temporary file with `File.binwrite` | DEC-34, FR-043 | Keeps the fixture list to DEC-34; a file written at test time keeps its bytes on every system, whatever Git does to line endings on checkout | A fixture per case; a `.gitattributes` file to protect fixture bytes |
| P21 | The input file that exists but cannot be opened (AC-09.3a) is a folder at the input path | DEC-23, spec item 11 | It exists (the start check passes) and cannot be read as a file on Linux, macOS and Windows, even as an administrator | Removing read permission (does not work on Windows or as root) |
| P22 | The partial-write test passes accounts whose second account raises `Errno::ENOSPC` when its number is asked for, so the writer has written one line before the failure | DEC-27, FR-026 | Reaches the "writing fails partway" path with a fake passed in, no stub of `File` | Filling a disk; stubbing `File#write` on every instance |
| P23 | The total-check fake `ChangingTotalRepository` wraps a real `AccountRepository`; `add`, `include?` and `find` pass through; `all` returns the real accounts on its first call and, from the second call, the first account replaced by an `Account` with 1.00 less | DEC-24, page 9 picks 46, 47 | Gives 66750.00 before and 66749.00 after on the sample balances, exactly AC-08.5 | Changing a real account's balance from the test |
| P24 | Phases run outside-in: a phase first writes its runner scenarios or end-to-end spec and the unit specs of the classes it builds, sees them fail, then writes the classes. The User Story 6 phase adds no code: its scenarios check behaviour built and unit-tested earlier, so they are expected to pass when first run, and any failure is fixed test-first in the class that owns it | constitution IV, brief rule 4 | Every behaviour is still specified by a spec seen to fail first (the unit spec); the scenario specs prove what the user sees | Writing the scenario specs only after all the code (no failing step) |
| P25 | End-to-end specs run `Open3.capture3({ 'LOG_LEVEL' => nil }, RbConfig.ruby, <project root>/bin/run, *arguments, chdir: <temporary folder>)` | DEC-34, FR-044, NFR-04 | `ruby bin/run` works on Windows too (DEC-37); removing `LOG_LEVEL` keeps the default warn level whatever the developer's shell has | Running `bin/run` through the shebang (fails on Windows) |
| P26 | `bin/run` starts with `#!/usr/bin/env ruby`, requires `../lib/infrastructure/runner` and calls `exit(Runner.new.run(ARGV))`; it is committed with the executable bit (`git update-index --chmod=+x bin/run`) | DEC-22, FR-037, page 6 pick 42 | Runs as `bin/run` on Linux and macOS and as `ruby bin/run` on Windows | A `.rb` extension |
| P27 | The `Runner` rescues exactly the five run-stopping errors, listed once as `Runner::STOPPING_ERRORS`; any other error is not rescued | DEC-25, page 9 pick 45, FR-034 | A bug still shows its stack trace and exits with 1 | A catch-all `rescue StandardError` |
| P28 | The start check for the output path uses `File.file?`; the start checks for the input files use `File.exist?` | DEC-23, DEC-25, spec items 11 and 15 | A folder at the output path must pass the start check and fail when written; a folder at an input path exists and fails when opened | `File.exist?` for the output path |
| P29 | `CsvRows` reads with `CSV.open` and `csv.shift`, one row at a time | DEC-32, DEC-05, DEC-07, research R1 | DEC-32 says the transfers file is read one row at a time with Ruby's CSV library (`CSV.open`, one row per `shift`), so the physical line number of each row is kept (DEC-07); after each `shift`, `csv.line` gives the raw line that DEC-05's blank test and the physical-line count need | A block-style read that yields only the parsed rows (no line number, no raw line) |
| P30 | `CsvRows` sets the opened file to read bytes (`csv.to_io.set_encoding(Encoding::BINARY)`, after `bom\|utf-8` has dropped any byte-order mark) and checks each row's raw line as UTF-8 itself, raising `UnreadableFile.at_line` at the first row that is not valid text; each field is then taken as UTF-8 text | DEC-04, DEC-07, DEC-32, FR-005, research R1, R2 | The csv gem checks the encoding of everything it has sampled to find the line ending (the whole of a small file) before giving the first row, so bytes that are not UTF-8 on line 2 would stop the read before line 1 is given, against FR-005; checking each row keeps `CSV.open`, one row per `shift`, and gives the rows before the bad line first | Relying on the gem's `InvalidEncodingError` (raised before any row, with a row count rather than a physical line); a fixed `row_sep` to stop the sampling (breaks CR LF files); reading lines by hand (DEC-04 and DEC-32 name the CSV library) |

## Complexity Tracking

No violation of the constitution; nothing to justify.
