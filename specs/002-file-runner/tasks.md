# Tasks: File reading, the day's run and the runner

**Input**: Design documents from `specs/002-file-runner/`: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/components-api.md](contracts/components-api.md), [contracts/command-line.md](contracts/command-line.md), [quickstart.md](quickstart.md). The `/speckit-tasks` input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#speckit-tasks-002-file-runner).

**Prerequisites**: `001-domain` is implemented: the project skeleton (`Gemfile`, `.rspec`, `.rubocop.yml`, `.gitignore`, `spec/spec_helper.rb`, `spec/support/builders.rb`) and every domain class, member and message in `001`'s [contract](../001-domain/contracts/domain-api.md). This spec starts from the end of `001`'s implementation branch.

**Tests**: required. Tests come first in every phase (constitution IV, [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34)): write the spec, run it and see the new examples fail, then write the code until they pass. Every phase ends with `bundle exec rspec` passing in random order and `bundle exec rubocop` reporting zero offences. The test split follows brief rule 4: this spec runs every page 2 scenario through `Runner` with real CSV files and exact standard output, standard error and exit status, including the scenarios of FR-03 to FR-06, which `001` owns and unit-tests; the domain's messages are never rewritten here.

**Organization**: phases follow the order the code depends on and build outside-in (plan P24). Phase 2 builds the file reading and path showing every story needs. Phase 3 is the MVP: the sample files from `bin/run` to the report (User Story 1). Phases 4 to 7 add the balances problems (US2), the transfers rejections (US3), the end of a completed run (US4) and the runner's own checks (US5). Phase 8 runs the domain scenarios through the runner (US6). Phases 9 and 10 are the design review (US7) and the suite checks (US8).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task).
- **[Story]**: the user story in [spec.md](spec.md) the task belongs to.
- IDs in brackets after a task name the requirement (FR-0nn in the spec, FR-nn and NFR-nn on pages 2 and 3), the acceptance scenario (AC-nn.n), the decision (DEC-nn), the spec's decided-in-the-run item (item n) and the plan's (Pnn) it serves.

## Conventions for every spec task

- Each spec file starts with `# frozen_string_literal: true`, requires the class under test with `require 'application/<file>'` or `require 'infrastructure/<file>'`, and has one top-level `RSpec.describe <Class>` (plan P1, P19; `001` plan D13, D16).
- One expectation per example; examples of at most 5 lines; at most 3 levels of nesting (`001` plan D17). A scenario's standard output, standard error, exit status and output file are separate examples sharing one memoised `subject(:run)`.
- Strings that a test compares are copied character for character from the spec: the acceptance scenarios, the [run-stopping messages table](spec.md#run-stopping-messages), and `001`'s domain messages (SC-003). Never change an expected string to match the code.
- The spec's `balances.csv` is the three lines `1111234522226789,100.00`, `1212343433335665,50.00`, `0000123412341234,0.00`, total 150.00. The fixed run time is `Time.new(2026, 11, 7, 14, 30, 5)`; the default output path for it is `output/final_balances_2026-11-07_143005.csv`.
- **Runner scenarios** (spec item 1, plan P18): in `spec/infrastructure/runner_spec.rb`, grouped by FR in `describe` blocks, each scenario is a `describe` named after its criterion (for example `describe 'AC-01.4 an invalid file reports every problem and stops the run'`; `RSpec/ContextWording` applies only to `context`, so no `context` text starts with `AC-`; nesting stays within 3 levels), with `subject(:run) { run_scenario(files: { ... }, arguments: [...], env: { ... }) }`. `run_scenario` writes the files into a temporary folder used as the current folder; its default files are `balances.csv` as above and `transfers.csv` holding the one row `1111234522226789,1212343433335665,10.00` (AC-01.1's file; spec item 23), its default arguments `balances.csv transfers.csv output/final_balances_2026-11-07_143005.csv`, its default environment `{}`. The shared examples `'a completed run'` (`stdout:`, `stderr:` with the default `''`, `output_file: nil`) and `'a stopped run'` (`stderr:`) check each stream exactly, with `<timestamp>`, `<pid>` and `<reason from the system>` matched by `stream_pattern` (spec item 10); `'a stopped run'` also checks that standard output is empty, the exit status is 1 and no output file was left (SC-004).
- Where a scenario's standard output is Template A or R, the example builds it with `template_a` or `template_r` from `spec/support/report_templates.rb`; lines marked **(derived)** in the spec are checked the same way.
- An example that proves an edge case names its DEC ID in its description, for example `stops with UnreadableFile, not NoTransfers, when line 1 cannot be read (DEC-04, DEC-20)`.

---

## Phase 1: Setup

**Purpose**: the sample data, the copies the tests use, and the helper for temporary folders (FR-038; DEC-22, DEC-34).

- [ ] T001 Copy `docs/challenge/mable_account_balances.csv` and `docs/challenge/mable_transactions.csv` to `data/mable_account_balances.csv` and `data/mable_transactions.csv` with `cp`, unchanged; never edit `docs/challenge/` [FR-038; DEC-22; item 14; research R11]
- [ ] T002 [P] Copy the same two files to `spec/fixtures/sample/mable_account_balances.csv` and `spec/fixtures/sample/mable_transactions.csv` with `cp`, unchanged [FR-038, FR-043; DEC-34; item 14]
- [ ] T003 Run `git diff --no-index` between each original and each copy and confirm there is no difference (depends on T001, T002) [FR-038; SC-001]
- [ ] T004 [P] Create `spec/support/files.rb` with a one-line comment and the helpers `in_temp_folder { |folder| ... }` (`Dir.mktmpdir`, `Dir.chdir(folder) { ... }`, folder removed afterwards), `write_file(name, text)` (creates folders, writes with `File.binwrite`) and `fixture_path(*parts)` (a path under `spec/fixtures/`) [DEC-34; P17, P20; research R9]
- [ ] T005 Run `bundle exec rspec` (all of `001`'s examples pass, random order) and `bundle exec rubocop` (`no offenses detected`) as the starting point (depends on T004) [NFR-05, NFR-06; DEC-34, DEC-36]

**Checkpoint**: the copies equal the originals; the suite and RuboCop are green.

---

## Phase 2: Foundational - reading the files and showing paths

**Purpose**: the reading rules both files share and the one rule for showing a path, which every user story needs (FR-001 to FR-006, FR-029, FR-030; DEC-04 to DEC-07, DEC-23, DEC-26, DEC-32). No user story can be built before this phase.

### Tests (write first)

- [ ] T006 [P] Create the fixture files, each exactly as listed, with no other content [FR-043; DEC-34; P20]:
  - `spec/fixtures/reading/blank_lines.csv`: line 1 `1111234522226789,100.00`, line 2 empty, line 3 three spaces, line 4 one tab, line 5 `1212343433335665,50.00`;
  - `spec/fixtures/reading/header_row.csv`: `account,balance` then `1111234522226789,100.00`;
  - `spec/fixtures/reading/byte_order_mark.csv`: the bytes `EF BB BF` then `1111234522226789,100.00` and a line feed (write it with `File.binwrite` once and commit the file);
  - `spec/fixtures/reading/unclosed_quote.csv`: line 1 `1111234522226789,100.00`, line 2 `1212343433335665,"50.00` (a quote that is never closed);
  - `spec/fixtures/reading/empty.csv`: zero bytes;
  - `spec/fixtures/reading/only_blank_lines.csv`: an empty line, a line of three spaces, an empty line;
  - `spec/fixtures/reading/field_counts.csv`: lines `1`, `1,2`, `1,2,3`, `1,2,3,4`.
- [ ] T007 [P] Write `spec/infrastructure/row_spec.rb` [FR-003, FR-004; DEC-06, DEC-19; P2]:
  - `wrong_field_count?` is false for 3 fields with `expected_size: 3`, and true for 2 and for 4;
  - `header_hint` is nil when not given, and returns the text when given;
  - two `Row`s with the same members are equal.
- [ ] T008 [P] Write `spec/infrastructure/csv_rows_spec.rb`, with `CsvRows.new(path, 2)` unless an example says otherwise, collecting the yielded rows as `[line_number, fields, header_hint]` [FR-001 to FR-005; DEC-04 to DEC-07, DEC-23; P3, P20; research R1, R2]:
  - blank lines (`blank_lines.csv`): yields two rows, at lines 1 and 5; the empty line, the line of spaces and the line with a tab are not rows (DEC-05, DEC-07);
  - an empty file (`empty.csv`) and a file of blank lines only (`only_blank_lines.csv`) yield no row and raise nothing (DEC-05, DEC-11, DEC-20);
  - a byte-order mark (`byte_order_mark.csv`): the first field is `1111234522226789`, with no mark, and the row has no header hint (DEC-04);
  - a header row (`header_row.csv`): line 1 has `header_hint` `This looks like a header row; files must not have a header.` (`CsvRows::HEADER_HINT`); line 2 has none (DEC-06);
  - the hint only on the first data row: a written file whose line 1 is empty and line 2 is `account,balance` marks line 2; a file whose line 1 is `1111234522226789,100.00` and line 2 `account,balance` marks neither (DEC-06);
  - no hint when the first field has a digit (`1111O34522226789,100.00`) or is empty (`,100.00`, and the row `,,` with `expected_size` 3) (DEC-06);
  - the hint on a header-looking first row with the wrong number of fields (`account,balance,x`, `expected_size` 2; `from,to` with `expected_size` 3) (DEC-06; page 10 pick 51);
  - Windows line endings and no final newline, written with `File.binwrite` as `"1111234522226789,100.00\r\n1212343433335665,50.00"`: two rows, lines 1 and 2, fields with no `\r` (DEC-04);
  - a quoted value and spaces around values, written as `"\"1111234522226789\", 100.00 \n"`: fields `1111234522226789` and `100.00` (DEC-04; AC-01.2);
  - tabs around a value are trimmed and spaces inside kept: `"1111234522226789,\t100.00\t\n"` gives `100.00`; `"1111234522226789,1 0\n"` gives `1 0` (DEC-04, DEC-05; clarification 1, item 18);
  - a line of commas is a row: `",,\n"` with `expected_size` 3 gives one row with fields `["", "", ""]` (DEC-05);
  - a quoted value over two lines, written as `"1111234522226789,100.00\n1212343433335665,\"50\n.00\"\n0000123412341234,0.00\n"`: rows at lines 1, 2 and 4 (DEC-07);
  - the expected size is kept on each row, so `field_counts.csv` with `expected_size` 3 gives `wrong_field_count?` true, true, false, true for lines 1 to 4 (DEC-04, DEC-19);
  - an unclosed quote (`unclosed_quote.csv`): yields line 1 first, then raises `UnreadableFile` with the message `cannot read <path> from line 2. Check for an unclosed quote or characters that are not text.` and `line_number` 2 (DEC-04, DEC-07);
  - bytes that are not UTF-8, written as `"1111234522226789,100.00\n1212343433335665,\xFF50.00\n"` in binary: yields line 1, then raises `UnreadableFile` at line 2 with the same message form (DEC-04);
  - a missing file (`fixture_path('reading', 'missing.csv')`, which does not exist) raises `UnreadableFile` whose message matches `cannot read file <path>: ` followed by non-empty text, with `line_number` nil (DEC-23; P9);
  - a folder at the path raises `UnreadableFile` whose message matches `cannot read file <path>: ` followed by non-empty text (DEC-23; P21);
  - the reason is the system's text without Ruby's call details: the message for the missing file does not contain ` @ ` (P9).
- [ ] T009 [P] Write `spec/infrastructure/balances_csv_reader_spec.rb` [FR-003, FR-006; DEC-04, DEC-11; P4]:
  - `BalancesCsvReader::FIELD_COUNT` is 2;
  - `each_row(path)` gives `Row`s with `expected_size` 2: in a written file `1111234522226789,100.00` is not marked and `1212343433335665,abc,9` is marked `wrong_field_count?`;
  - it is built with no path, and reads the path it is given (two different files read by one reader).
- [ ] T010 [P] Write `spec/infrastructure/transfers_csv_reader_spec.rb` [FR-003, FR-005, FR-006; DEC-04, DEC-19, DEC-20, DEC-32; P4]:
  - `TransfersCsvReader::FIELD_COUNT` is 3;
  - `field_counts.csv` gives `Row`s with `expected_size` 3, marked wrong on lines 1, 2 and 4 (DEC-19);
  - one row at a time: with `unclosed_quote.csv`, the block has already received line 1 when `UnreadableFile` is raised (DEC-32, DEC-04);
  - a written file whose line 1 is `"1111234522226789,1212343433335665,"10.00` raises `UnreadableFile` at line 1 before any row is given, not an empty read (DEC-04, DEC-20; item 16).
- [ ] T011 [P] Write `spec/infrastructure/display_path_spec.rb`, building every folder from `Dir.tmpdir` so the paths are real on every system, with no file needing to exist [FR-029, FR-030; DEC-26; P10; research R3]:
  - a file in the folder: `DisplayPath.of(File.join(folder, 'day1.csv'), folder)` is `day1.csv`;
  - a relative path is kept relative: `DisplayPath.of('output/day1.csv', folder)` is `output/day1.csv`;
  - below the folder: `output/final_balances_2026-11-07_143005.csv`;
  - below the parent: from `<root>/project/docs`, the file `<root>/project/output/final_balances_2026-11-07_143005.csv` is `../output/final_balances_2026-11-07_143005.csv` (AC-08.4);
  - two steps up: from `<root>/a/sub`, the file `<root>/b/day1.csv` is shown in full, as `File.expand_path` gives it (AC-08.4; item 3);
  - outside: from `<root>/project/docs`, `File.expand_path('/day1.csv')` is shown in full (AC-08.4);
  - a path already in its shown form is unchanged (`../output/x.csv` from the same folder) (P10);
  - with no folder given, the current folder is used (inside `in_temp_folder`, `DisplayPath.of(File.join(Dir.pwd, 'b.csv'))` is `b.csv`).
- [ ] T012 Run `bundle exec rspec spec/infrastructure` and confirm every new example fails because the classes do not exist (depends on T006 to T011)

### Implementation

- [ ] T013 Create `lib/infrastructure/errors.rb` with a one-line comment per class and `UnreadableFile < StandardError`: `UnreadableFile.cannot_open(path, error)` (message `cannot read file <path>: <reason>`, where `<path>` is `DisplayPath.of(path)` (P11) and `<reason>` is `error.message` up to ` @ `; `line_number` nil), `UnreadableFile.at_line(path, line_number)` (message with `<path>` as `DisplayPath.of(path)`: `cannot read <path> from line <N>. Check for an unclosed quote or characters that are not text.`), readers `path` and `line_number`, `line_problem` (`<path>` shown the same way: `cannot read <path> from this line. Check for an unclosed quote or characters that are not text.`) and `stop_reason` (`cannot read file`) [FR-005, FR-009, FR-030, FR-034; DEC-04, DEC-23, DEC-26; P8, P9, P11] (depends on T017)
- [ ] T014 [P] Create `lib/infrastructure/row.rb`: `Row = Data.define(:line_number, :fields, :expected_size, :header_hint)` with `initialize(line_number:, fields:, expected_size:, header_hint: nil)` and `wrong_field_count?` (`fields.size != expected_size`) [FR-003, FR-004; P2]
- [ ] T015 Create `lib/infrastructure/csv_rows.rb`: `CsvRows::HEADER_HINT`, `CsvRows.new(path, expected_size)`, `include Enumerable`, `each` as in research R1 and R2 (`CSV.open(path, 'r:bom|utf-8')`, the running count of physical lines (before each `shift` the row's line is the count plus 1; after it the count grows by the line breaks in `csv.line`; `csv.lineno` is not used, as it does not count a quoted newline), blank by the raw line, trimming spaces and tabs, `nil` to `""`, the header hint only on the first non-blank row whose first field is not empty and has no digit, `CSV::MalformedCSVError` to `UnreadableFile.at_line`, `SystemCallError` to `UnreadableFile.cannot_open`); every method within 10 lines (depends on T013, T014) [FR-001 to FR-005; DEC-04 to DEC-07; P3; research R1, R2]
- [ ] T016 [P] Create `lib/infrastructure/balances_csv_reader.rb` (`FIELD_COUNT = 2`, `each_row(path, &)` through `CsvRows`) and `lib/infrastructure/transfers_csv_reader.rb` (`FIELD_COUNT = 3`, the same) (depends on T015) [FR-006; DEC-32; P4]
- [ ] T017 [P] Create `lib/infrastructure/display_path.rb`: `DisplayPath.of(path, folder = Dir.pwd)` as in research R3 (`File.expand_path`, `Pathname#relative_path_from`, at most one leading `..`, full path otherwise or on `ArgumentError`) [FR-029, FR-030; DEC-26; P10]
- [ ] T017a Run `bundle exec rspec` until every example passes in random order, and `bundle exec rubocop` until it reports zero offences (depends on T013 to T017)

**Checkpoint**: `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences. Every file-level edge case of DEC-04 to DEC-07 is green.

---

## Phase 3: User Story 1 - The sample files give the exact expected result (Priority: P1) MVP

**Goal**: `bin/run` with the sample files gives AC-08.1's exact report, the exact output file and exit status 0 (FR-08, FR-09; DEC-22, DEC-26, DEC-27, DEC-35). Builds the happy path of every class: `LoadBalances`, `DayResult`, `FinalBalancesCsvWriter`, `ReportPrinter`, `ProcessDailyTransfer`, `Runner` and `bin/run`. Problems, rejections and stops come in later phases.

**Independent Test**: the sample-files end-to-end spec and the AC-08.1 runner scenario.

### Tests for User Story 1 (write first)

- [ ] T018 [P] [US1] Add to `spec/support/builders.rb` `balances_row(line, *fields, header_hint: nil)` and `transfers_row(line, *fields, header_hint: nil)`, building `Row`s with `expected_size` 2 and 3 [DEC-34; P17]
- [ ] T019 [P] [US1] Create `spec/support/fakes.rb` with a one-line comment per helper [DEC-24, DEC-28, DEC-34; P17; research R9]:
  - `FakeReader.new(rows, unreadable_at: nil, error: nil)`: `each_row(path)` records the path in `paths`; when `error` is given it raises that error object before yielding any row (for example `UnreadableFile.cannot_open(path, Errno::EACCES.new)`); otherwise it yields the rows, then raises `UnreadableFile.at_line(path, unreadable_at)` when that is set;
  - `FakeReporter`: `print(day_result)` appends to `printed`, recording too whether the day result's output file existed at that moment (`File.exist?(day_result.output_path)`) in `file_existed`;
  - `memory_logger(level = Logger::INFO)`, returning a `Logger` on a `StringIO`, and `log_lines(logger)`, returning each line as `"<LEVEL> <text>"` (for example `"WARN Line 1 rejected: ..."`).
- [ ] T020 [P] [US1] Create `spec/support/report_templates.rb`: `template_a(transfer:, balances:)` and `template_r(line:, reason:)`, giving the spec's Templates A and R exactly, with `Output file: output/final_balances_2026-11-07_143005.csv` as the last line and a final line feed [FR-027; DEC-21, DEC-26; item 17]
- [ ] T021 [US1] Create `spec/support/runs.rb` [FR-044, FR-045; DEC-34; P17, P25; research R9, R10]:
  - `run_runner(*arguments, env: {})`: `Runner.new(stdout: StringIO.new, stderr: StringIO.new, env: env).run(arguments)`, returning a `Struct` with `stdout`, `stderr` and `status`;
  - `run_scenario(files: { 'balances.csv' => <balances.csv>, 'transfers.csv' => <AC-01.1's row> }, arguments: [<defaults>], env: {}, folder: nil)`: inside `in_temp_folder`, writes the defaults with the given `files` merged over them (a given file replaces the default of the same name; the value `:folder` makes a folder of that name instead; `nil` leaves that default out), changes into `folder` (a subfolder, created) when given, runs `run_runner`, and returns the `Struct` with `output_file` too: the bytes of `output/final_balances_2026-11-07_143005.csv` in the temporary folder, or nil when absent;
  - `stream_pattern(text)`: an anchored `Regexp` of the escaped text, with `<timestamp>` as `\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{6}`, `<pid>` as `\d+` and `<reason from the system>` as `.+`;
  - the shared examples `'a completed run'` and `'a stopped run'` described in the conventions;
  - `run_command(*arguments, files:)`: copies the given fixture files into a new temporary folder under the given names, runs `Open3.capture3({ 'LOG_LEVEL' => nil }, RbConfig.ruby, <project root>/bin/run, *arguments, chdir: <folder>)`, and returns `stdout` and `stderr` with each `"\r\n"` turned into `"\n"`, `status` (`exitstatus`) and `output_file` (`File.binread` of `output/final_balances_2026-11-07_143005.csv`, or nil) (clarification 5, item 22).
- [ ] T022 [US1] Write `spec/acceptance/runner_run_sample_files_spec.rb`, `RSpec.describe Runner, '#run'` with `describe 'with sample files'`: `run_command('data/mable_account_balances.csv', 'data/mable_transactions.csv', 'output/final_balances_2026-11-07_143005.csv', files: <the two spec/fixtures/sample/ files under data/>)`; examples: standard output is exactly AC-08.1's report; standard error is empty; exit status 0; the output file's bytes are exactly `"1111234522226789,4820.50\n1111234522221234,9974.40\n2222123433331212,1550.00\n1212343433335665,1725.60\n3212343433335755,48679.50\n"` (DEC-35) [AC-08.1; FR-044; DEC-22, DEC-26, DEC-27, DEC-34, DEC-35; SC-001; item 2; P19, P25]
- [ ] T023 [US1] Write the first part of `spec/infrastructure/runner_spec.rb`, `RSpec.describe Runner` [FR-031, FR-032, FR-037; AC-08.1, AC-09.1; DEC-22, DEC-27, DEC-30; items 1, 3]:
  - `describe 'FR-08 The end-of-day result and its output'`, `describe 'AC-08.1 the sample files give the exact expected result'`: `run_scenario` with the sample copies as `data/mable_account_balances.csv` and `data/mable_transactions.csv` and the arguments `data/mable_account_balances.csv data/mable_transactions.csv output/final_balances_2026-11-07_143005.csv`; `it_behaves_like 'a completed run'` with AC-08.1's standard output, empty standard error and the five-line output file (DEC-35);
  - `describe 'FR-09 The runner'`, `describe 'AC-09.1 arguments'`, with `ProcessDailyTransfer.new` stubbed to return `instance_double(ProcessDailyTransfer, call: nil)` and to record the keywords it was given, run from a temporary folder holding `b.csv` and `t.csv`: with no arguments, `call` receives paths that expand to the project root's `data/mable_account_balances.csv` and `data/mable_transactions.csv`, and an output path that expands to the project root joined with `FinalBalancesCsvWriter.default_path(<the recorded run_time>)`; with `b.csv t.csv`, paths that expand to `b.csv` and `t.csv` in the temporary folder and the same default output path; with `b.csv t.csv out/day1.csv`, an output path that expands to `out/day1.csv` in the temporary folder; every path given is absolute (P11); each case returns 0; nothing is written in the project's `output/` (DEC-22, DEC-27; item 3);
  - `ProcessDailyTransfer.new` is given a `run_time` that is a `Time`, and the six parts `balances_reader` (`BalancesCsvReader`), `transfers_reader` (`TransfersCsvReader`), `writer` (`FinalBalancesCsvWriter`), `repository` (`AccountRepository`), `reporter` (`ReportPrinter`) and `logger` (`Logger`) (DEC-30; P6, P12).
- [ ] T024 [P] [US1] Write `spec/application/load_balances_spec.rb`, the valid file only, with a `FakeReader` and a real `AccountRepository` [FR-007, FR-011; AC-01.1; DEC-08, DEC-10, DEC-31; P5; research R4]:
  - the three rows of `balances.csv` are added in file order: `repository.all` gives the numbers `1111234522226789`, `1212343433335665`, `0000123412341234` and the balances `100.00`, `50.00`, `0.00` (two examples);
  - leading zeros are kept: `0000123412341234` is found with `AccountNumber.new('0000123412341234')` (DEC-08);
  - a starting balance of `0.00` is accepted (DEC-10);
  - the reader is asked once, with the path given to `call` (`paths` is `['balances.csv']`);
  - `call` returns nil.
- [ ] T025 [P] [US1] Write `spec/application/day_result_spec.rb`, applied results only [FR-022; DEC-26; P7]:
  - the five members return what was given;
  - with two applied `TransferResult`s: `processed_count` 2, `applied_count` 2, `rejected_count` 0, `rejected_counts` `{}`, `all_rejected?` false;
  - with no results, `all_rejected?` is false;
  - `DayResult::ALL_REJECTED_WARNING` is `All transfers were rejected; check this is the right file.` (DEC-21).
- [ ] T026 [P] [US1] Write `spec/infrastructure/final_balances_csv_writer_spec.rb`, the happy path, inside `in_temp_folder` [FR-024, FR-025; AC-08.3, AC-09.7; DEC-27; P13; research R6]:
  - `default_path(Time.new(2026, 11, 7, 14, 30, 5))` is `output/final_balances_2026-11-07_143005.csv` (DEC-27);
  - a 24-hour clock with leading zeros: `default_path(Time.new(2026, 1, 2, 9, 5, 7))` is `output/final_balances_2026-01-02_090507.csv` and `Time.new(2026, 11, 7, 23, 59, 59)` gives `..._235959.csv` (DEC-27);
  - one second apart: `14:30:05` and `14:30:06` give `..._143005.csv` and `..._143006.csv` (AC-09.7; item 4);
  - `write(accounts, 'out/day1.csv')` with the three accounts of `balances.csv` writes exactly the bytes `"1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n"`: load order, 2 decimal places, full numbers, no header, LF only, last line included (`File.binread`) (DEC-27; page 10 pick 17);
  - missing folders are created: `write(accounts, 'out/new/day1.csv')` with no `out/` folder creates the file (DEC-27; AC-08.3);
  - the writer is built with no arguments and writes to the path it is given.
- [ ] T027 [P] [US1] Write `spec/infrastructure/report_printer_spec.rb`, applied rows and the output path, printing to a `StringIO` with `current_folder` set [FR-027, FR-029; AC-08.1, AC-08.4; DEC-26; P14, P15]:
  - for the sample day (four applied results with the sample rows as written, totals `66750.00`, the five final accounts, output path `output/final_balances_2026-11-07_143005.csv` inside the current folder), the output is exactly AC-08.1's report (DEC-26, DEC-35);
  - an applied amount written `10` or `007.50` in the row is shown `10.00` or `7.50` (P15);
  - the output path below a parent of the current folder is shown with `../` (`Output file: ../output/final_balances_2026-11-07_143005.csv` from `<root>/project/docs`), and one outside it in full (`Output file: ` and `File.expand_path('/day1.csv')`) (AC-08.4; item 3);
  - nothing is written to standard error (`expect { ... }.not_to output.to_stderr`).
- [ ] T028 [P] [US1] Write `spec/application/process_daily_transfer_spec.rb`, the completed day with applied rows only, inside `in_temp_folder`, with `FakeReader`s, a real `AccountRepository`, a real `FinalBalancesCsvWriter`, a `FakeReporter`, `memory_logger` and the fixed run time [FR-012, FR-013, FR-015, FR-019, FR-020, FR-022, FR-023; AC-08.1; DEC-15, DEC-26, DEC-27, DEC-28, DEC-30; P6, P15; research R5]:
  - with `balances.csv`'s rows and the transfers rows `1111234522226789,1212343433335665,10.00` and `1212343433335665,1111234522226789,5.00`, `call('balances.csv', 'transfers.csv', 'output/day.csv')` returns a `DayResult` with two applied results in file order (line numbers 1 and 2), totals `150.00` and `150.00`, final balances `95.00`, `55.00`, `0.00` in load order, and output path `output/day.csv` (four examples);
  - the output file holds the final balances (`File.binread`);
  - the reporter is called exactly once, with that `DayResult`, and the output file already existed when it was called (DEC-26);
  - the log lines at info are exactly `INFO Run started: balances balances.csv, transfers transfers.csv`, `INFO Line 1 applied: ************6789 -> ************5665 10.00`, `INFO Line 2 applied: ************5665 -> ************6789 5.00`, `INFO Run ended: processed 2, applied 2, rejected 0` (DEC-28, DEC-29);
  - the `Run started` line shows each path by `DisplayPath.of`: called with the absolute paths of `balances.csv` and `transfers.csv` in the temporary folder, the line is still `INFO Run started: balances balances.csv, transfers transfers.csv`, and `DayResult#output_path` is the absolute output path given (P11);
  - an applied amount written `007.50` is logged as `7.50` (P15);
  - with the output path left out, the file written is `output/final_balances_2026-11-07_143005.csv` in the current folder, named from the run time given (DEC-27, DEC-30; page 6 pick 35);
  - the balances reader is asked with `balances.csv` and the transfers reader with `transfers.csv` (page 6 pick 36);
  - the balances are loaded before any transfer is read: when the balances reader (`FakeReader.new([], error: UnreadableFile.cannot_open('balances.csv', Errno::EACCES.new))`) raises, that error leaves `call` unchanged and the transfers reader's `paths` is empty (DEC-12; spec User Story 2 scenario 11);
  - leaving out a part raises `KeyError` when built (P6).
- [ ] T029 [US1] Run `bundle exec rspec` and confirm the new examples of T022 to T028 fail (missing classes, missing `bin/run`) (depends on T018 to T028)

### Implementation for User Story 1

- [ ] T030 [P] [US1] Create `lib/application/load_balances.rb`: `LoadBalances.new(reader, repository)`; `call(path)` reads every row and, for each, builds `AccountNumber.new(fields[0])`, `Money.balance(fields[1])`, `Account.new(number, money)`, `repository.add`, and records the row's line as the account's first line; returns nil (problems come in Phase 4) [FR-007; DEC-31; P5]
- [ ] T031 [P] [US1] Create `lib/application/day_result.rb`: `DayResult = Data.define(:results, :total_before, :total_after, :accounts, :output_path)` with `ALL_REJECTED_WARNING`, `processed_count`, `applied_count`, `rejected_count`, `rejected_counts` (tally of `reason` ordered by `TransferResult::REASON_CODES`, only codes that occurred) and `all_rejected?` (any results and all rejected) [FR-022; DEC-19, DEC-21, DEC-26; P7]
- [ ] T032 [P] [US1] Create `lib/infrastructure/final_balances_csv_writer.rb`: `default_path(run_time)` (`run_time.strftime('%Y-%m-%d_%H%M%S')`); `write(accounts, path)`: `FileUtils.mkdir_p(File.dirname(path))`, `File.open(path, File::WRONLY | File::CREAT | File::EXCL | File::BINARY)`, one `"#{account.number},#{account.balance}\n"` per account as it goes (errors come in Phase 6) [FR-024, FR-025; DEC-27; P13; research R6]
- [ ] T033 [P] [US1] Create `lib/infrastructure/report_printer.rb`: `ReportPrinter.new(output: $stdout, current_folder: Dir.pwd)`; `print(day_result)` writes the sections Transfers (applied lines with `Money.amount(fields[2]).to_s`), Summary (`Processed`, `Applied`, `Rejected`, `Total before`, `Total after`), Final balances and `Output file: <DisplayPath.of(output_path, current_folder)>`, separated by one empty line, two spaces between the parts of a line (rejected lines and the warning come in Phase 5) [FR-027, FR-029; DEC-26; P14, P15]
- [ ] T034 [US1] Create `lib/application/process_daily_transfer.rb`: `ProcessDailyTransfer.new(run_time: Time.now, **parts)` keeping exactly the six named parts (`parts.fetch` for each, so a missing one raises `KeyError`); `call(balances_path, transfers_path, output_path = nil)` in the order of research R5 for applied rows: default output path, `Run started` log (paths shown by `DisplayPath.of`, P11), `LoadBalances`, total before (`repository.all.map(&:balance).reduce(:+)`), each row through `AccountNumber`, `AccountNumber`, `Money.amount`, `Transfer`, `TransferService#apply` and `TransferResult.applied`, the `Line <N> applied` info log with masked numbers, total after, `writer.write(repository.all, output_path)`, the `DayResult`, `reporter.print`, `Run ended` log, return the `DayResult`; masking private (depends on T030, T031, T032) [FR-012, FR-013, FR-019, FR-020, FR-023; DEC-15, DEC-26, DEC-28 to DEC-30; P6; research R5]
- [ ] T035 [US1] Create `lib/infrastructure/runner.rb`: `Runner.new(stdout: $stdout, stderr: $stderr, env: ENV)`; `PROJECT_ROOT`; `run(arguments)` for 0, 2 or 3 arguments: paths resolved to real, absolute paths (typed against the current folder, defaults against `PROJECT_ROOT`) and passed on as they are (P11); a logger `Logger.new(stderr, level: Logger::WARN)` (`LOG_LEVEL` comes in Phase 7); `Time.now` once; the output path (third argument, or `PROJECT_ROOT` joined with `FinalBalancesCsvWriter.default_path(run_time)`, real); the real parts; `ProcessDailyTransfer.new(run_time:, ...).call(...)`; return 0 (depends on T034) [FR-031, FR-032; DEC-22, DEC-27, DEC-30; P11, P12; research R7]
- [ ] T036 [US1] Create `bin/run` (`#!/usr/bin/env ruby`, `# frozen_string_literal: true`, `require_relative '../lib/infrastructure/runner'`, `exit(Runner.new.run(ARGV))`) and set its executable bit with `git update-index --add --chmod=+x bin/run` (depends on T035) [FR-037; DEC-22; P26]
- [ ] T037 [US1] Run `bundle exec rspec` until every example passes in random order, then `bundle exec rubocop` until it reports zero offences; run `bin/run` (or `ruby bin/run`) once from the project root and delete the file it wrote in `output/` (depends on T030 to T036) [SC-001]

**Checkpoint (MVP)**: the sample files give exactly AC-08.1 through `bin/run` as a separate process and through `Runner`; `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 4: User Story 2 - The balances file is loaded, or every problem in it is reported (Priority: P1)

**Goal**: every balances problem is listed with its line, in field order, and the run stops before any transfer (FR-01; DEC-04 to DEC-12, DEC-31). Adds `InvalidBalancesFile`, the full `LoadBalances` and the `Runner`'s handling of a run-stopping error.

**Independent Test**: `load_balances_spec.rb` with fake readers; the FR-01 runner scenarios; the invalid-balances end-to-end spec.

### Tests for User Story 2 (write first)

- [ ] T038 [P] [US2] Add to `spec/application/load_balances_spec.rb` a `describe` for problems; each example calls `call` with a `FakeReader` and checks the raised `InvalidBalancesFile`'s `message` or `problems` exactly [FR-007 to FR-011; AC-01.3 to AC-01.10; DEC-06, DEC-07, DEC-11, DEC-12, DEC-31; P8; research R4]:
  - AC-01.4's rows (lines 1, 3, 4, 5, 6, 7) give the message `"the balances file is invalid (5 problems):\n  Line 3: account number \"12345\" must be exactly 16 digits\n  Line 4: expected 2 fields, found 3\n  Line 5: account 1111234522226789 appears more than once (first on line 1)\n  Line 6: balance \"-5.00\" must not be negative\n  Line 7: balance \"1.234\" has more than 2 decimal places"` (DEC-07, DEC-11, DEC-12);
  - one problem uses the singular: a single row `12345,50.00` gives `"the balances file is invalid (1 problem):\n  Line 1: account number \"12345\" must be exactly 16 digits"` (item 6);
  - a row with several problems reports each, in field order, same line: `12345,abc` gives `Line 1: account number "12345" must be exactly 16 digits` then `Line 1: balance "abc" is not a valid amount` (DEC-12; AC-01.5);
  - the field count is the only problem of its row, for 1 and 3 fields: `1111234522226789` gives `Line 1: expected 2 fields, found 1`; `1111234522226789,5000.00,x` gives `Line 1: expected 2 fields, found 3` (page 10 pick 7; AC-01.6);
  - `1111234522226789,` gives `Line 2: balance is empty`; `,` gives `account number "" must be exactly 16 digits` and `balance is empty` (AC-01.6);
  - a duplicate with the same balance and one with a different balance are both reported, naming the first line (DEC-11, DEC-12);
  - the duplicate comes before the balance problem: `1111234522226789,5000.00` then `1111234522226789,abc` gives `Line 2: account 1111234522226789 appears more than once (first on line 1)` then `Line 2: balance "abc" is not a valid amount` (page 10 pick 13; AC-01.10);
  - the known gap: a first copy that was not added is not seen as a duplicate: line 1 `1111234522226789,abc`, `1111234522226789,5000.00,x` or `1111234522226789,-5.00`, then line 2 `1111234522226789,10.00`, each give only line 1's problem and `(1 problem)` (DEC-12; clarification 2, item 19);
  - the duplicate names the line the repository's copy was added from: line 1 invalid, line 2 valid, line 3 the same number gives `(first on line 2)` (page 6 pick 30);
  - the header hint follows the account-number problem: a row `account,balance` marked with the hint gives `Line 1: account number "account" must be exactly 16 digits. This looks like a header row; files must not have a header.` and `Line 1: balance "balance" is not a valid amount` (DEC-06; AC-01.7);
  - the header hint follows the field-count problem: `account,balance,x` marked gives `Line 1: expected 2 fields, found 3. This looks like a header row; files must not have a header.` (DEC-06; page 10 pick 51);
  - an unmarked row with letters in its number has no hint: `1111O34522226789,100.00` gives `Line 1: account number "1111O34522226789" must be exactly 16 digits` (DEC-06);
  - an invalid number and a negative balance in one row both report: `12345,-5.00` (page 10 pick 26);
  - no rows: `InvalidBalancesFile` with the message `the balances file has no rows: balances.csv` (DEC-11; page 10 pick 32);
  - an unreadable line is the last problem: rows at lines 1 to 4 (line 3 `12345,100.00`) and `unreadable_at: 7` give `Line 3: ...` then `Line 7: cannot read balances.csv from this line. Check for an unclosed quote or characters that are not text.` and `(2 problems)` (DEC-04, DEC-12; AC-01.9; page 10 pick 9);
  - an unreadable line 1 with no rows before it gives `(1 problem)` with that line, not the no-rows message (DEC-04, DEC-11);
  - a file that cannot be opened passes through: a reader (`FakeReader.new([], error: UnreadableFile.cannot_open('balances.csv', Errno::EACCES.new))`) makes `call` raise that same error object (page 10 pick 33);
  - `stop_reason` is `balances file invalid: 5 problems` for AC-01.4's rows, and `balances file invalid: 1 problem` for no rows (P8; AC-01.8).
- [ ] T039 [P] [US2] Add to `spec/infrastructure/runner_spec.rb` `describe 'FR-01 Load the balances file'`, one `describe` per scenario, named with its AC ID, with the files and arguments the spec gives, and the shared examples with the spec's exact streams [FR-031, FR-034, FR-036, FR-045; AC-01.1 to AC-01.10; DEC-04 to DEC-12, DEC-25, DEC-28; items 1, 9]:
  - AC-01.1 (`transfers.csv` holding `1111234522226789,1212343433335665,10.00`): `'a completed run'` with `template_a` (`1111234522226789 -> 1212343433335665  10.00`; `90.00`, `60.00`, `0.00`) (DEC-08, DEC-10);
  - AC-01.2: `balances.csv` written as the bytes `EF BB BF` then `"\"1111234522226789\", 100.00 \r\n1212343433335665,50.00\r\n0000123412341234,0.00"`; the same completed run as AC-01.1 (DEC-04);
  - AC-01.3 (line 2 empty, line 3 spaces, line 4 `12345,50.00`): `'a stopped run'` with the spec's standard error (DEC-05, DEC-07);
  - AC-01.4: `'a stopped run'` with the spec's standard error (5 problems);
  - AC-01.5 (`12345,abc`): `'a stopped run'`, 2 problems;
  - AC-01.6, one `describe` per table row (line 1 `1212343433335665,50.00`, line 2 the row): `1111234522226789,`, `1111234522226789,abc`, `1111234522226789,5000.00,x`, `,`;
  - AC-01.7: `account,balance` then `balances.csv`; and the two variants (`1111O34522226789,100.00`; `account,balance,x`) (DEC-06);
  - AC-01.8: `bin/run empty.csv transfers.csv` with `empty.csv` empty, and again holding only blank lines: `Error: the balances file has no rows: empty.csv` then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: balances file invalid: 1 problem` (DEC-11);
  - AC-01.9: `bin/run bad.csv transfers.csv` with `bad.csv` as the spec completes it (lines 1 and 2 of `balances.csv`, line 3 `12345,100.00`, line 4 `0000123412341234,0.00`, lines 5 and 6 empty, line 7 `1111234522226789,"100.00`) (DEC-04, DEC-12);
  - AC-01.10 and its known-gap variants (DEC-12; item 19);
  - User Story 2 scenario 11: AC-01.5's `balances.csv` with an empty `transfers.csv`: only the balances error (DEC-12, DEC-20);
  - the error log line names no account number: in AC-01.4's standard error, the line starting `E, [` holds no run of 16 digits (DEC-28).
- [ ] T040 [P] [US2] Create the fixture files `spec/fixtures/acceptance/balances.csv` (the spec's `balances.csv`), `spec/fixtures/acceptance/invalid_balances.csv` (AC-01.4's file, line 2 empty) and `spec/fixtures/acceptance/mixed_rejections_transfers.csv` (AC-08.2's five rows) [FR-043; DEC-34]
- [ ] T041 [US2] Write `spec/acceptance/runner_run_invalid_balances_spec.rb`, `RSpec.describe Runner, '#run'` with `describe 'with invalid balances'`: `run_command('balances.csv', 'transfers.csv', 'output/final_balances_2026-11-07_143005.csv', files: { 'balances.csv' => invalid_balances.csv, 'transfers.csv' => mixed_rejections_transfers.csv })`; examples: standard output empty; standard error matches AC-01.4's exactly (`stream_pattern`); exit status 1; no output file (depends on T040) [AC-01.4; FR-044; DEC-12, DEC-25, DEC-34; item 2]
- [ ] T042 [US2] Run `bundle exec rspec` and confirm the examples that need this phase's new code fail (no `InvalidBalancesFile`, no problem collection, no `Error:` handling): every example of T038 except the `cannot_open` pass-through, every scenario group of T039 except AC-01.1 and AC-01.2, and T041. Three already pass, as P24 says: the `cannot_open` pass-through of T038 (`LoadBalances` never rescues it; its unit example first failed in T028 and T029), and T039's AC-01.1 and AC-01.2 (first failed in T024 and T029 for the valid file, and in T008 for the byte-order mark, CR LF and missing final newline) (depends on T038 to T041)

### Implementation for User Story 2

- [ ] T043 [US2] Create `lib/application/errors.rb` with a one-line comment and `InvalidBalancesFile < StandardError`: `new(problems)` (message `the balances file is invalid (<count>):` followed by `"\n  " + problem` for each; `<count>` `1 problem` or `<n> problems`), `InvalidBalancesFile.no_rows(path)` (message `the balances file has no rows: <path>` with `<path>` as `DisplayPath.of(path)` (P11), one problem), `problems`, `stop_reason` (`balances file invalid: <count>`) [FR-010; DEC-11, DEC-12; P8; item 6]
- [ ] T044 [US2] Complete `lib/application/load_balances.rb` with the five steps of research R4: field count first (with the hint), the account number (with the hint), `include?` and the duplicate text `DuplicateAccount.new(number).message + " (first on line <M>)"`, the balance with `Money.balance` and `Account.check_opening_balance`, add only a row with no problem; problems as `Line <N>: <text>`; `UnreadableFile` with a line number becomes the last problem, one without is re-raised; then `InvalidBalancesFile.new(problems)` or `InvalidBalancesFile.no_rows(path)`; rescue only `InvalidAccountNumber`, `InvalidAmount` and `NegativeBalance` (depends on T043) [FR-007 to FR-011; DEC-06, DEC-11, DEC-12, DEC-31; research R4]
- [ ] T045 [US2] Add to `lib/infrastructure/runner.rb` `STOPPING_ERRORS` (`InvalidBalancesFile`, `UnreadableFile` for now) and the rescue in `run`: `stderr.puts("Error: #{error.message}")`, `logger.error("Run stopped: #{error.stop_reason}")`, return 1 (depends on T043) [FR-034, FR-036; DEC-25, DEC-28; P8, P27; research R7]
- [ ] T046 [US2] Run `bundle exec rspec` until every example passes in random order and `bundle exec rubocop` reports zero offences (depends on T043 to T045)

**Checkpoint**: every FR-01 scenario gives its exact streams through `Runner` and `bin/run`; `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 5: User Story 3 - The transfers file is read one row at a time, in file order (Priority: P1)

**Goal**: each transfers row becomes an applied or rejected `TransferResult` with one reason, in file order, with no retry; a rejected row is logged with masked numbers; an empty file or one that cannot be read past a line stops the run; every row rejected still completes with a warning (FR-02, FR-07; DEC-04 to DEC-07, DEC-14 to DEC-16, DEC-19 to DEC-21, DEC-28, DEC-29, DEC-32).

**Independent Test**: `process_daily_transfer_spec.rb` with fake readers; the FR-02 and FR-07 runner scenarios; the all-rejected end-to-end spec.

### Tests for User Story 3 (write first)

- [ ] T047 [P] [US3] Add to `spec/application/process_daily_transfer_spec.rb` a `describe` for rejected rows, with `balances.csv`'s rows, a one-row or few-row transfers `FakeReader` and `memory_logger` at info; each example checks the result's `reason`, a balance, or one log line [FR-013 to FR-017, FR-020, FR-021; AC-02.1 to AC-02.5, AC-03.2, AC-07.1; DEC-06, DEC-13 to DEC-16, DEC-19 to DEC-21, DEC-28, DEC-29; items 8, 20; research R5]:
  - each domain error becomes its code: `12345,1212343433335665,10.00` and `1111234522226789,12345,10.00` `invalid_account_number`; `1111234522226789,1212343433335665,abc` and `...,0` `invalid_amount`; `1212343433335665,1212343433335665,5.00` `same_account`; `9999888877776666,1111234522226789,10.00` and `1111234522226789,9999888877776666,10.00` `unknown_account`; `1111234522226789,1212343433335665,100.01` `insufficient_funds` (DEC-19);
  - the values are built in field order: `12345,1212343433335665,abc` gives `invalid_account_number`, not `invalid_amount` (FR-014; DEC-19);
  - a row marked with the wrong number of fields gives `malformed_row` without building any value, for 1, 2 and 4 fields, even when its values would also fail (`9999888877776666,1111234522226789` gives `malformed_row`) (DEC-19);
  - the header hint is carried into the rejected result: a row marked with `CsvRows::HEADER_HINT` gives a result whose `header_hint` is that text (DEC-06);
  - a rejected transfer changes no balance and the next row is processed: `1111234522226789,1212343433335665,90.00`, `1111234522226789,1212343433335665,100.01` then `1212343433335665,1111234522226789,5.00` give final balances `15.00`, `135.00`, `0.00` (DEC-14, DEC-18; AC-03.2);
  - one pass, no retry, repeats applied: AC-07.1's three rows give `insufficient_funds`, applied, applied, and final balances `60.00`, `50.00`, `40.00` (DEC-15, DEC-16; AC-07.1);
  - the warn log line of a rejected row: `WARN Line 2 rejected: ************6789 -> ************5665 100.01 insufficient_funds` (DEC-28, DEC-29);
  - masking of values that are not account numbers: `12345` as `*2345`; `from` as `****`; an empty value as `****`; `1111-2345-2222-6789` as `***************6789` (DEC-29; AC-09.6);
  - an empty amount is logged as `""`: `,,` gives `WARN Line 1 rejected: **** -> **** "" invalid_account_number` (page 10 pick 11; AC-02.2);
  - fields by position for a wrong field count: 2 fields `WARN Line 4 rejected: ************6789 -> ************5665 malformed_row`; 1 field `WARN Line 1 rejected: ************6789 malformed_row`; 4 fields (`1111234522226789,1212343433335665,1,000.00`) `WARN Line 1 rejected: ************6789 -> ************5665 1 malformed_row` (page 10 pick 12; item 8);
  - the header hint never appears in a log line: `from,to,amount` marked gives `WARN Line 1 rejected: **** -> **** amount invalid_account_number` (FR-021);
  - at warn level only warn and error lines are logged: with `memory_logger(Logger::WARN)`, a day with one applied and one rejected row logs only the rejected line (DEC-28);
  - the run end counts each reason in DEC-19 order: AC-08.2's rows end with `INFO Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)` (DEC-19, DEC-28);
  - every row rejected: `from,to,amount` alone still returns a `DayResult`, writes the output file and calls the reporter once; the log ends `WARN Line 1 rejected: ...`, `WARN All transfers were rejected; check this is the right file.`, `INFO Run ended: processed 1, applied 0, rejected 1 (invalid_account_number 1)` (DEC-21);
  - no rows: an empty transfers `FakeReader` raises `NoTransfers` with the message `the transfers file has no transfers: transfers.csv`; no output file exists; the reporter is never called; the log holds `INFO Run started: ...` and no `Run ended` (DEC-20; item 20);
  - `NoTransfers#stop_reason` is `transfers file has no transfers` (P8);
  - a file that cannot be read past a line: rows 1 (`...,100.01`, rejected) and `unreadable_at: 2` raise `UnreadableFile`; the warn line for line 1 was logged; no output file exists; the reporter is never called; no `Run ended` (DEC-04; AC-02.5; item 20).
- [ ] T048 [P] [US3] Add to `spec/application/day_result_spec.rb` the rejected cases [FR-022; DEC-19, DEC-21, DEC-26; P7]:
  - `rejected_counts` lists only the codes that occurred, in DEC-19 order, whatever the file order: results rejected `insufficient_funds`, `same_account`, `unknown_account` give `{ same_account: 1, unknown_account: 1, insufficient_funds: 1 }` in that order;
  - a header row counts as processed and rejected (DEC-26): one rejected result gives `processed_count` 1, `rejected_count` 1;
  - `all_rejected?` is true when every result is rejected, false when one is applied.
- [ ] T049 [P] [US3] Add to `spec/infrastructure/report_printer_spec.rb` the rejected lines and the warning [FR-027, FR-028; AC-02.1 to AC-02.3; DEC-06, DEC-19, DEC-21, DEC-26; page 10 picks 10 to 12; item 8]:
  - AC-02.3's day gives exactly AC-02.3's standard output, the warning after the summary and before the final balances (DEC-21);
  - AC-02.1's day gives exactly AC-02.1's standard output, with no warning (DEC-26);
  - a rejected line shows the values as written and the code: `  Line 3  rejected  1212343433335665 -> 9999888877776666  10.00  unknown_account`;
  - an empty value is `""`: `  Line 1  rejected  "" -> ""  ""  invalid_account_number` (page 10 pick 11);
  - a header row shows `: ` and the hint after the code (AC-02.3's line);
  - a wrong field count shows no values: `  Line 4  rejected  malformed_row: 2 fields, expected 3`; with 1 field `malformed_row: 1 fields, expected 3` (item 8); with the hint `  Line 1  rejected  malformed_row: 2 fields, expected 3. This looks like a header row; files must not have a header.` (page 10 pick 10);
  - the counts per reason are indented four spaces, in DEC-19 order, between `Rejected:` and `Total before:` (AC-08.2's summary).
- [ ] T050 [P] [US3] Add to `spec/infrastructure/runner_spec.rb` `describe 'FR-02 Read the transfers file'` and `describe 'FR-07 The order transfers are applied in'`, one `describe` per scenario, named with its AC ID, with the spec's exact streams [FR-045; AC-02.1 to AC-02.5, AC-07.1; DEC-04 to DEC-07, DEC-14 to DEC-16, DEC-19 to DEC-21; items 1, 17]:
  - AC-02.1 (line 2 empty, line 3 spaces): `'a completed run'` with the spec's standard output and the one warn line;
  - AC-02.2 (`,,`): `template_r` and the two warn lines;
  - AC-02.3 (`from,to,amount`): the spec's standard output, the two warn lines, and the output file `"1111234522226789,100.00\n1212343433335665,50.00\n0000123412341234,0.00\n"`; and the `from,to` variant with `template_r` (DEC-06, DEC-21, DEC-26);
  - AC-02.4: `bin/run balances.csv empty.csv` with `empty.csv` empty, and again holding only blank lines: `'a stopped run'` with `Error: the transfers file has no transfers: empty.csv` and `Run stopped: transfers file has no transfers` (DEC-20);
  - AC-02.5: `bin/run balances.csv bad.csv` with line 2 `1111234522226789,"10.00`: `'a stopped run'` with the spec's two lines; and the `100.01` variant, whose standard error starts with the warn line (DEC-04);
  - AC-07.1: `'a completed run'` with the spec's standard output and warn line (DEC-15, DEC-16).
- [ ] T051 [P] [US3] Create `spec/fixtures/acceptance/all_rejected_transfers.csv` holding the one line `from,to,amount`, and write `spec/acceptance/runner_run_all_rejected_spec.rb`, `RSpec.describe Runner, '#run'` with `describe 'with all rejected'`: `run_command` with `balances.csv` and this file as `transfers.csv` and the third argument; examples: standard output exactly AC-02.3's; standard error matches AC-02.3's two warn lines; exit status 0; the output file's bytes are `balances.csv`'s three lines, each ending with LF [AC-02.3; FR-044; DEC-06, DEC-21, DEC-34; item 2]
- [ ] T052 [US3] Run `bundle exec rspec` and confirm the examples that need this phase's new code fail (domain errors escape, no rejected lines, no warning, no `NoTransfers`): all of T047, T049 and T051, and in T050 the AC-02.1, AC-02.2, AC-02.3 (both variants), AC-02.4, AC-07.1 and AC-02.5 `100.01` variant groups. These already pass, as P24 says: all of T048 (`DayResult`'s counting was built in T031 and first failed in T025 and T029), and T050's AC-02.5 main scenario group (the reader's `at_line` first failed in T008 and T010; the `Runner` has rescued `UnreadableFile` since T045) (depends on T047 to T051)

### Implementation for User Story 3

- [ ] T053 [US3] Add `NoTransfers < StandardError` to `lib/application/errors.rb`: `new(path)`, message `the transfers file has no transfers: <path>` with `<path>` as `DisplayPath.of(path)` (P11), `stop_reason` `transfers file has no transfers` [FR-016; DEC-20; P8]
- [ ] T054 [US3] Complete `lib/application/process_daily_transfer.rb` (research R5): `malformed_row` for a row with `wrong_field_count?`; the frozen `Hash` of the five domain errors to their codes and the rescue that builds `TransferResult.rejected` with the code and `row.header_hint`; the warn line by position with masked values and `""` for an empty amount; `NoTransfers` when no row was read; the warn `DayResult::ALL_REJECTED_WARNING` when every result is rejected; `Run ended` with the counts per reason from the `DayResult`; every method within 10 lines and the class within 100 (depends on T053) [FR-013 to FR-017, FR-020, FR-021; DEC-14 to DEC-16, DEC-19 to DEC-21, DEC-28, DEC-29; P6, P7]
- [ ] T055 [P] [US3] Complete `lib/infrastructure/report_printer.rb`: rejected lines (values as written, `""` for empty, `: <hint>` after the code), the `malformed_row: <K> fields, expected <TransfersCsvReader::FIELD_COUNT>` line (`. <hint>`), the counts per reason, and `Warning: <DayResult::ALL_REJECTED_WARNING>` as its own section when `all_rejected?` [FR-027, FR-028; DEC-06, DEC-21, DEC-26]
- [ ] T056 [US3] Add `NoTransfers` to `Runner::STOPPING_ERRORS` in `lib/infrastructure/runner.rb` (depends on T053) [FR-034; DEC-20, DEC-25]
- [ ] T057 [US3] Run `bundle exec rspec` until every example passes in random order and `bundle exec rubocop` reports zero offences (depends on T053 to T056)

**Checkpoint**: every FR-02 and FR-07 scenario gives its exact streams through `Runner`, and AC-02.3 through `bin/run`; `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 6: User Story 4 - A completed run checks the total, writes a new output file, then prints the report (Priority: P1)

**Goal**: the total check, the writer's no-overwrite and failure rules, and the full FR-08 scenarios (FR-08; DEC-24 to DEC-27).

**Independent Test**: the total-check split across `process_daily_transfer_spec.rb` and `runner_spec.rb`; `final_balances_csv_writer_spec.rb`; the FR-08 runner scenarios; the mixed-rejections end-to-end spec.

### Tests for User Story 4 (write first)

- [ ] T058 [P] [US4] Add `ChangingTotalRepository` to `spec/support/fakes.rb` (plan P23): wraps a real `AccountRepository`; `add`, `include?` and `find` pass through; `all` returns the real accounts on its first call and, from the second call, the first account replaced by `Account.new(first.number, first.balance - Money.amount('1.00'))` [DEC-24; page 10 pick 46]
- [ ] T059 [P] [US4] Add to `spec/application/process_daily_transfer_spec.rb` a `describe` for the total check and the end of the run, inside `in_temp_folder` [FR-013, FR-018, FR-019, FR-046; AC-08.5; DEC-24, DEC-25, DEC-26; page 10 picks 46, 47]:
  - with the sample balances and transfers as `FakeReader` rows, a `ChangingTotalRepository`, the real `FinalBalancesCsvWriter` and the output path `output/day.csv`: `call` raises `TotalChanged` with the message `the total of all balances changed from 66750.00 to 66749.00. No output file was written.`;
  - in the same set-up, with `subject(:call_day)` the call (`expect { call_day }.to raise_error(TotalChanged)` in its own example), a separate example uses `before { attempt(TotalChanged) { call_day } }` (the `attempt(error_class)` helper of `spec/support/builders.rb`, 001 plan D17, which rescues only that error) and checks that `output/day.csv` does not exist;
  - and the `FakeReporter` was never called;
  - `TotalChanged#stop_reason` is `total of all balances changed` (P8);
  - a writer that raises `OutputNotWritable` (an `instance_double(FinalBalancesCsvWriter)`): the error leaves `call` unchanged and the reporter is never called (DEC-25).
- [ ] T060 [P] [US4] Add to `spec/infrastructure/final_balances_csv_writer_spec.rb` a `describe` for failures, inside `in_temp_folder` [FR-026; AC-09.4; DEC-25, DEC-27; P13, P22; clarification 4, item 21; research R6]:
  - a file that appeared at the path: `write` raises `OutputNotWritable` whose message matches `cannot write output file out/day1.csv: ` and non-empty text (page 6 pick 40);
  - and that file's bytes are unchanged;
  - a folder at the path (`out`): `OutputNotWritable` with `cannot write output file out: ` and non-empty text (page 10 pick 14);
  - and the folder is still there;
  - writing fails partway: accounts whose second account raises `Errno::ENOSPC` when its `number` is asked for: `OutputNotWritable` (P22);
  - and no file is left at the path (DEC-27);
  - a missing folder that cannot be created (a file `blocker` where the folder `blocker/` should be, path `blocker/sub/day1.csv`): `OutputNotWritable` with `cannot write output file blocker/sub/day1.csv: ` and non-empty text;
  - and no output file exists;
  - `OutputNotWritable#stop_reason` is `cannot write output file` (P8).
- [ ] T061 [P] [US4] Add to `spec/infrastructure/runner_spec.rb`, in `describe 'FR-08 The end-of-day result and its output'` [FR-045, FR-046; AC-08.2 to AC-08.5, AC-09.4; DEC-24 to DEC-27; items 3, 5, 9]:
  - AC-08.2: `'a completed run'` with the spec's standard output, three warn lines and the output file `"1111234522226789,0.00\n1212343433335665,80.00\n0000123412341234,70.00\n"`;
  - AC-08.3, the output file fed back in: a run with `balances.csv` holding AC-08.2's output file and `transfers.csv` holding `1212343433335665,1111234522226789,10.00` (the spec's values): standard output is Template A with `1212343433335665 -> 1111234522226789  10.00` and the balances `10.00`, `70.00`, `70.00`, standard error is empty, exit status 0 (DEC-27; item 5);
  - AC-08.3, a third argument with missing folders: `bin/run balances.csv transfers.csv out/new/day1.csv` (AC-01.1's transfers) creates `out/new/day1.csv`, the last report line is `Output file: out/new/day1.csv`, standard error is empty, exit status 0 (DEC-27; item 9);
  - AC-08.4, run from a subfolder: `run_scenario(files: <balances.csv and AC-01.1's transfers.csv>, folder: 'docs', arguments: %w[../balances.csv ../transfers.csv ../output/final_balances_2026-11-07_143005.csv])`: the last report line is `Output file: ../output/final_balances_2026-11-07_143005.csv`; standard error empty; exit status 0 (DEC-26; item 3);
  - AC-08.4, a file outside: from the subfolder `docs`, with the output path in a second temporary folder: the last report line is `Output file: ` and that folder's full path joined with `day1.csv`; standard error empty; exit status 0 (DEC-26; item 3; P10);
  - AC-08.5: with `balances.csv` and AC-01.1's `transfers.csv` present so the start checks pass, `ProcessDailyTransfer.new` stubbed to return an `instance_double(ProcessDailyTransfer)` whose `call` raises `TotalChanged.new(Money.amount('66750.00'), Money.amount('66749.00'))`: `'a stopped run'` with `Error: the total of all balances changed from 66750.00 to 66749.00. No output file was written.` and `E, [<timestamp> #<pid>] ERROR -- : Run stopped: total of all balances changed` (DEC-24; page 10 pick 46);
  - AC-09.4: `bin/run balances.csv transfers.csv out` with `out` an existing folder: `'a stopped run'` with `Error: cannot write output file out: <reason from the system>` and `E, [<timestamp> #<pid>] ERROR -- : Run stopped: cannot write output file`; `out` is still an empty folder (DEC-25; page 10 pick 14).
- [ ] T062 [US4] Write `spec/acceptance/runner_run_mixed_rejections_spec.rb`, `RSpec.describe Runner, '#run'` with `describe 'with mixed rejections'`: `run_command` with `spec/fixtures/acceptance/balances.csv` and `mixed_rejections_transfers.csv` as `balances.csv` and `transfers.csv` and the third argument; examples: standard output exactly AC-08.2's; standard error matches AC-08.2's three warn lines; exit status 0; the output file's bytes as in T061 [AC-08.2; FR-044; DEC-14, DEC-19, DEC-26 to DEC-28, DEC-34; item 2]
- [ ] T063 [US4] Run `bundle exec rspec` and confirm the examples that need this phase's new code fail (no total check, no `OutputNotWritable`, raw system errors): all of T059, all of T060, and in T061 the AC-08.5 and AC-09.4 scenario groups. These already pass, as P24 says: in T061, AC-08.2, the output file fed back in, the missing folders of AC-08.3 and both AC-08.4 scenario groups, and T062 (mixed rejections end to end); the behaviour was built and first failed earlier (the writer's `mkdir_p` and the report printer's output line in T026, T027, T029; the rejected rows in T047 to T052) (depends on T058 to T062)

### Implementation for User Story 4

- [ ] T064 [P] [US4] Add `TotalChanged < StandardError` to `lib/application/errors.rb`: `new(before, after)`, readers `before` and `after`, message `the total of all balances changed from <before> to <after>. No output file was written.` with `Money#to_s`, `stop_reason` `total of all balances changed` [FR-018; DEC-24; P8]
- [ ] T065 [P] [US4] Add `OutputNotWritable < StandardError` to `lib/infrastructure/errors.rb`: `new(path, error)`, message `cannot write output file <path>: <reason>` (`<path>` as `DisplayPath.of(path)` (P11); reason up to ` @ `), `stop_reason` `cannot write output file` [FR-026; DEC-25; P8, P9]
- [ ] T066 [US4] Add the total check to `lib/application/process_daily_transfer.rb`: total after from `repository.all`, `TotalChanged.new(before, after)` when they differ, before the writer is called (depends on T064) [FR-013, FR-018, FR-019; DEC-24]
- [ ] T067 [US4] Add the failure handling to `lib/infrastructure/final_balances_csv_writer.rb` (research R6 step 4): `SystemCallError` or `IOError` while creating folders or opening becomes `OutputNotWritable` with nothing deleted; while writing lines, the file is closed and deleted, then `OutputNotWritable` (depends on T065) [FR-026; DEC-25, DEC-27; P13]
- [ ] T068 [US4] Add `TotalChanged` and `OutputNotWritable` to `Runner::STOPPING_ERRORS`, which now lists all five (depends on T064, T065) [FR-034; DEC-25; P27]
- [ ] T069 [US4] Run `bundle exec rspec` until every example passes in random order and `bundle exec rubocop` reports zero offences (depends on T066 to T068)

**Checkpoint**: every FR-08 scenario gives its exact streams; AC-08.2 through `bin/run`; the total check is tested in both specs; `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 7: User Story 5 - The runner starts the run, reports every stop clearly and sets the exit status (Priority: P1)

**Goal**: the argument count, the start checks reported together, an input file that cannot be opened, `LOG_LEVEL`, masking only in logs, repeated runs, every exit status, and no catch-all (FR-09; DEC-02, DEC-03, DEC-22, DEC-23, DEC-25, DEC-28, DEC-29).

**Independent Test**: the FR-09 runner scenarios; the wrong-arguments end-to-end spec.

### Tests for User Story 5 (write first)

- [ ] T070 [P] [US5] Add to `spec/infrastructure/runner_spec.rb`, in `describe 'FR-09 The runner'`, one `describe` per scenario, named with its AC ID [FR-031 to FR-036, FR-045; AC-09.2 to AC-09.8; DEC-02, DEC-03, DEC-22, DEC-23, DEC-25, DEC-28, DEC-29; page 10 pick 45; items 11, 13, 15, 20]:
  - AC-09.2: with 1 argument (`balances.csv`), with 4 (`a b c d`), with `-h` and with `--help`: standard output empty; standard error exactly `"Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]\nWith no arguments, runs the sample files in data/.\n"`, with no log line; exit status 1; no `output/` folder created (DEC-22);
  - AC-09.3: `missing1.csv missing2.csv out/day1.csv` with `out/day1.csv` existing (`old`): `'a stopped run'` with the spec's three `Error:` lines in the order balances, transfers, output and `Run stopped: start checks failed (file not found, output file already exists)`; `out/day1.csv` still holds `old` (DEC-23, DEC-25; page 10 pick 18);
  - AC-09.3, only the two missing files: `Run stopped: start checks failed (file not found)`;
  - AC-09.3, only an existing output file (`balances.csv transfers.csv out/day1.csv`): `Error: output file already exists: out/day1.csv. Delete it or give another output path.` then `Run stopped: start checks failed (output file already exists)`; the file unchanged;
  - an existing folder at the output path passes the start check: covered by AC-09.4 in Phase 6 (item 15);
  - AC-09.3a (`files: { 'balances.csv' => :folder }`: the default `balances.csv` file is replaced by a folder of that name, with the default `transfers.csv` present, so the start checks pass): a folder named `balances.csv` (plan P21): `'a stopped run'` with `Error: cannot read file balances.csv: <reason from the system>` and `Run stopped: cannot read file`; and a folder named `transfers.csv` (`files: { 'transfers.csv' => :folder }`: the default `transfers.csv` file replaced by the folder, the default `balances.csv` file present): `Error: cannot read file transfers.csv: <reason from the system>` (DEC-23; item 11);
  - AC-09.5, `LOG_LEVEL` `info`, `INFO` and `Info`, with the sample copies in `data/` and the arguments of AC-08.1: standard output exactly AC-08.1's; standard error exactly the six info lines of AC-09.5 (DEC-28);
  - AC-09.5, `LOG_LEVEL` unset, `warn`, `debug` and ` info ` (with spaces), with the sample copies and the arguments of AC-08.1: `'a completed run'` with AC-08.1's standard output, standard error empty and exit status 0 (DEC-28; item 13);
  - AC-09.5, info level on a stopped run: AC-01.4's files with `LOG_LEVEL=info` run through `'a stopped run'` with standard output empty, standard error exactly `I, [<timestamp> #<pid>]  INFO -- : Run started: balances balances.csv, transfers transfers.csv` followed by AC-01.4's lines (no `Run ended`), and exit status 1 (DEC-28; item 20);
  - AC-09.5, info level with rejections: AC-08.2's files with `LOG_LEVEL=info` run through `'a completed run'` with AC-08.2's standard output, standard error exactly the spec's seven log lines in order, ending `Run ended: processed 5, applied 2, rejected 3 (same_account 1, unknown_account 1, insufficient_funds 1)`, and exit status 0 (DEC-28);
  - AC-09.6: in the info run on the sample files, the report shows `1111234522226789` in full and no log line holds a run of 16 digits (DEC-29);
  - AC-09.7: two runs on the sample copies with the output paths `output/final_balances_2026-11-07_143005.csv` and `output/final_balances_2026-11-07_143006.csv` give the same standard output apart from the `Output file:` line, and output files with the same bytes; for each run, standard output equals AC-08.1's report apart from the `Output file:` line, standard error is empty, and exit status is 0 (DEC-03; item 4);
  - AC-09.8 is covered by the exit-status example of every scenario; a completed run with every row rejected exits with 0 (AC-02.3, Phase 5);
  - leading zeros matched across both files, with fixture files: the files `spec/fixtures/leading_zeros/balances.csv` and `transfers.csv` copied in as `balances.csv` and `transfers.csv` give a completed run whose report shows `  Line 1  applied  0000123412341234 -> 1111234522226789  10.00` and the final balances `40.00`, `110.00` (DEC-08, DEC-34);
  - an unexpected error is not caught: with `balances.csv` and AC-01.1's `transfers.csv` present, `ProcessDailyTransfer.new` stubbed to return a stand-in whose `call` raises `RuntimeError`, `run_runner` raises that `RuntimeError` (page 10 pick 45).
- [ ] T071 [P] [US5] Create `spec/fixtures/leading_zeros/balances.csv` (`0000123412341234,50.00` and `1111234522226789,100.00`) and `spec/fixtures/leading_zeros/transfers.csv` (`0000123412341234,1111234522226789,10.00`) [FR-043; DEC-08, DEC-34]
- [ ] T072 [P] [US5] Write `spec/acceptance/runner_run_wrong_arguments_spec.rb`, `RSpec.describe Runner, '#run'` with `describe 'with wrong arguments'`: `run_command('balances.csv', files: {})`; examples: standard output empty; standard error exactly the two usage lines; exit status 1 [AC-09.2; FR-044; DEC-22, DEC-34; page 10 pick 3]
- [ ] T073 [US5] Run `bundle exec rspec` and confirm the examples that need this phase's new code fail (no usage check, no start checks, no `LOG_LEVEL`): in T070 the AC-09.2 scenario groups, the AC-09.3 scenario groups, the AC-09.5 scenario groups at info level (sample files, stopped run, rejections) and AC-09.6 (it runs at info level), and T072. These already pass, as P24 says: AC-09.3a (the reader's `cannot_open` first failed in T008; `UnreadableFile` is rescued by the `Runner` since T045 and T039), the AC-09.5 scenario groups at warn level (unset, `warn`, `debug`, ` info `; the warn default is T035's), AC-09.7 (`default_path` first failed in T026), AC-09.8 (shown by every scenario), the leading-zeros run (matching first failed in T024 and T008) and the not-caught-bug example (a regression guard on T045's rescue list, which names only the five run-stopping errors) (depends on T070 to T072)

### Implementation for User Story 5

- [ ] T074 [US5] Add to `lib/infrastructure/runner.rb` the usage check (0, 2 or 3 arguments; otherwise the two usage lines on `stderr`, no logger used, return 1) and the level from `LOG_LEVEL` (`env['LOG_LEVEL'].to_s.casecmp?('info')` gives `Logger::INFO`, otherwise `Logger::WARN`) [FR-031, FR-032, FR-035; DEC-22, DEC-28; P16; item 13]
- [ ] T075 [US5] Add the start checks to `lib/infrastructure/runner.rb`: `File.exist?` for the balances and transfers paths, `File.file?` for the output path; each problem as one `Error:` line in that order, with the path shown by `DisplayPath.of` (P11); then `logger.error("Run stopped: start checks failed (<reasons>)")` with `file not found` and `output file already exists`, each once and only if it occurred, joined by `, `; return 1 before any part is built (depends on T074) [FR-033; DEC-23, DEC-25; P28; page 10 pick 18]
- [ ] T076 [US5] Run `bundle exec rspec` until every example passes in random order and `bundle exec rubocop` reports zero offences (depends on T074, T075)

**Checkpoint**: every FR-09 scenario gives its exact streams; the usage run through `bin/run`; `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 8: User Story 6 - Every domain scenario gives its exact run outcome (Priority: P2)

**Goal**: the page 2 scenarios of FR-03 to FR-06, owned by `001`, run through the runner with real CSV files (brief rule 4). No code is added: the behaviour was built and unit-tested in Phases 3 to 5, so these examples are expected to pass when first run; a failure is fixed test-first in the class that owns the behaviour (plan P24).

**Independent Test**: one runner scenario per table row of the spec's User Story 6.

### Tests for User Story 6

- [ ] T077 [US6] Add to `spec/infrastructure/runner_spec.rb` `describe 'FR-03 to FR-06 (owned by 001)'`, the rows generated from one list in the spec file so each `describe` is named after its criterion and row; each writes the row as line 1 of `transfers.csv` with `balances.csv`, and uses `'a completed run'` with `template_a` (A rows, empty standard error) or `template_r` (R rows, the row's warn line then the all-rejected warn line) exactly as the spec's tables give them [FR-045; AC-03.1 to AC-06.3; DEC-08 to DEC-10, DEC-13, DEC-14, DEC-17 to DEC-19, DEC-26, DEC-28, DEC-29; item 17]:
  - FR-03: AC-03.1 (`30.00` applied; `70.00`, `80.00`, `0.00`); AC-03.3, its three rows (`invalid_account_number`, `invalid_amount`, `same_account`); AC-03.2 is shown by every R row, whose final balances are `balances.csv`'s (DEC-14, DEC-18);
  - FR-04: AC-04.1 (`100.01`, `insufficient_funds`); AC-04.2 (`100.00` applied, leaving exactly `0.00`: `0.00`, `150.00`, `0.00`) (DEC-13); AC-04.3 (`0.01` from the `0.00` account, `insufficient_funds`);
  - FR-05: AC-05.1 and AC-05.2 (`unknown_account`; the final balances list only the three loaded accounts) (DEC-17);
  - AC-06.1: the six from values, including `0000123412341234` (leading zeros matched, `insufficient_funds`) and the masks `***********2678`, `*************7890`, `************6789`, `***************6789` (DEC-08, DEC-29);
  - AC-06.2: `10`, `10.5`, `10.50`, `007.50` applied with the amounts shown `10.00`, `10.50`, `10.50`, `7.50`; the thirteen invalid amounts `0`, `0.00`, `-5.00`, `-0`, `-0.00`, `1.234`, `abc`, `10.`, `.50`, `+10`, `1e3`, `$10`, `1 0`, each shown as written with `invalid_amount`; the empty amount (`""`); `"1,000.00"` quoted (`1,000.00`, `invalid_amount`); `1,000.00` not quoted (`malformed_row: 4 fields, expected 3`, warn line with `1`) (DEC-09, DEC-10);
  - AC-06.3 is covered by the FR-01 scenarios of Phase 4.
- [ ] T078 [US6] Run `bundle exec rspec spec/infrastructure/runner_spec.rb`; every new example passes; for any that fails, write the failing unit example in the owning class's spec first, see it fail, fix the class, and run again. Then run the full `bundle exec rspec` until every example passes in random order, and `bundle exec rubocop` until it reports zero offences (depends on T077) [constitution IV; P24]

**Checkpoint**: every page 2 scenario of FR-01 to FR-09 runs through `Runner` with exact streams (SC-002); `bundle exec rspec` passes in random order; `bundle exec rubocop` reports zero offences.

---

## Phase 9: User Story 7 - The run's cost grows only with the size of the two files (Priority: P3)

**Goal**: NFR-03 by design review; no timing test and no large file (DEC-03, DEC-26, DEC-32).

- [ ] T079 [US7] Review `lib/application/` and `lib/infrastructure/` against the [time and space table](../../docs/solution-design/09-considerations.md#time-and-space) and record the result in the run report: `LoadBalances` does one `include?` and at most one `add` per row; each transfer does two `find`s through `TransferService`; each total and the writer visit each account once; no loop over rows or accounts inside another; O(m + n) time and space for the whole run (SC-007) [FR-039; NFR-03; DEC-32; US7 scenario 1]
- [ ] T080 [US7] Review that `CsvRows` holds one row at a time and nothing reads a whole file into a string; that one `TransferResult` per row is kept and nothing else grows with the transfers; that there is no fixed limit on accounts or rows [FR-040; NFR-03; DEC-26, DEC-32; US7 scenarios 2, 3, 5]
- [ ] T081 [US7] Review that nothing is kept between runs: no class variable, no global, no file written other than the output file; AC-09.7's two runs give the same result (Phase 7) [FR-041; NFR-03; DEC-03; US7 scenario 4]

**Checkpoint**: the design review finds 0 steps whose cost grows faster than the rows in the two files.

---

## Phase 10: User Story 8 - The tests prove every behaviour once, in any order (Priority: P2)

**Goal**: the suite's own properties (NFR-06; DEC-24, DEC-28, DEC-30, DEC-34, DEC-36).

- [ ] T082 [US8] Run `bundle exec rspec` three times in a row and confirm each passes with a different seed; confirm `coverage/index.html` is written each time and no minimum fails the run (SC-005) [FR-048; DEC-34, DEC-36; US8 scenario 1]
- [ ] T083 [US8] Confirm `spec/acceptance/` holds exactly five spec files (`runner_run_sample_files_spec.rb`, `runner_run_mixed_rejections_spec.rb`, `runner_run_all_rejected_spec.rb`, `runner_run_invalid_balances_spec.rb`, `runner_run_wrong_arguments_spec.rb`), each running `bin/run` as a separate process [FR-044; DEC-34; US8 scenario 4; SC-005]
- [ ] T084 [P] [US8] Search `spec/` for `Time.now`, `Date.today`, `allow(Time)`, `allow(Date)`, `$stdout`, `$stderr` and `STDOUT`: none is used to set up or stub a test (the only `Time` objects are built with `Time.new(...)`), and every `Runner` example passes its own `StringIO` streams (SC-006) [FR-047; DEC-28, DEC-30; US8 scenario 5]
- [ ] T085 [P] [US8] Review the test list against DEC-34: each rule tested once, at the level where it lives; one spec file per class; fixture files only those listed in T006, T040, T051 and T071 plus `spec/fixtures/sample/`; every edge case in the table below has its example; example names read as behaviour in documentation format [FR-042, FR-043, FR-048; DEC-34; US8 scenarios 2, 3, 6, 7]

**Checkpoint**: SC-005 and SC-006 hold.

---

## Phase 11: Polish and cross-cutting checks

- [ ] T086 Run `bundle exec rubocop` and confirm `no offenses detected` across `lib/`, `bin/run` and `spec/` (SC-008) [NFR-05, owned by `001`; DEC-36]
- [ ] T087 Run the [quickstart](quickstart.md) steps 1 to 14 by hand, including `bin/run` (`ruby bin/run` on Windows) from the project root and from `docs/`, and delete the files they write in `output/` [SC-001; DEC-22, DEC-26]
- [ ] T088 [P] Confirm `git ls-files -s bin/run` shows mode `100755`, `git status --short` lists nothing under `output/` or `coverage/`, and `git diff --no-index` shows no difference between `docs/challenge/` and `data/` or `spec/fixtures/sample/` [FR-037, FR-038; DEC-22, DEC-27]
- [ ] T089 [P] Review that no file under `lib/` has a comment explaining the design (only a one-line "what it is" per class) and that nothing in the report, the logs or the output names a company [DEC-02, DEC-30, DEC-37]

---

## Edge cases and their tests

Every edge case in the spec's [Edge Cases](spec.md#edge-cases) list, with the task that tests it.

| Edge case | Decision | Tasks |
|---|---|---|
| Byte-order mark, Windows line endings, no final newline | DEC-04 | T008, T039 (AC-01.2) |
| A line of spaces or tabs is blank; a line of commas is a row | DEC-05 | T008, T050 (AC-02.2) |
| Tabs trimmed; spaces inside a value kept | DEC-04, DEC-05 | T008 |
| Blank lines counted in line numbers | DEC-05, DEC-07 | T008, T039 (AC-01.3), T050 (AC-02.1) |
| A quoted value over several lines is reported at its first line | DEC-07 | T008 |
| Header hint: both files; none for digits or an empty first field; after a field-count problem | DEC-06 | T008, T038, T047, T049, T039 (AC-01.7), T050 (AC-02.2, AC-02.3) |
| A header row counts as processed and rejected | DEC-26 | T048, T050 (AC-02.3) |
| A balances row with the wrong number of fields reports only that | page 10 pick 7 | T038, T039 (AC-01.4, AC-01.6) |
| Several problems in a row, in field order; duplicate before balance | DEC-12 | T038, T039 (AC-01.5, AC-01.10) |
| The duplicate known gap (invalid or negative balance, wrong field count) | DEC-12 | T038, T039 (AC-01.10) |
| A duplicate with the same or a different balance names the first line | DEC-11, DEC-12 | T038, T039 (AC-01.4) |
| An empty balances file, or only blank lines | DEC-11 | T008, T038, T039 (AC-01.8) |
| An empty transfers file, or only blank lines | DEC-20 | T008, T047, T050 (AC-02.4) |
| An invalid balances file with an empty transfers file | DEC-12, DEC-20 | T028, T039 (scenario 11) |
| A balances file unreadable past a line: earlier problems first, counted | DEC-04, DEC-12 | T008, T038, T039 (AC-01.9) |
| A transfers file unreadable past a line: earlier transfers discarded | DEC-04 | T010, T047, T050 (AC-02.5) |
| A transfers file unreadable at line 1: `UnreadableFile`, not `NoTransfers` | DEC-04, DEC-20 | T010 |
| Bytes that are not UTF-8 | DEC-04 | T008 |
| Every transfer rejected, a header-only file included | DEC-21 | T047, T048, T049, T050, T051 |
| No retry; two equal rows both applied | DEC-15, DEC-16 | T047, T050 (AC-07.1) |
| A transfers row with 1, 2, 4 or more fields | DEC-19, DEC-28 | T010, T047, T049, T050 (AC-02.1), T077 |
| The output file already exists at the start | DEC-25 | T070 (AC-09.3) |
| The output file appears after the start checks | DEC-27 | T060 |
| The output path is an existing folder | DEC-25 | T060, T061 (AC-09.4) |
| Writing fails partway: partial file deleted | DEC-27 | T060 |
| Missing folders on the output path created | DEC-27 | T026, T061 (AC-08.3) |
| A missing folder that cannot be created | DEC-25, DEC-27 | T060 |
| The output file uses LF only | page 10 pick 17 | T026, T022, T051, T062 |
| The output path relative, with `../`, or in full | DEC-26 | T011, T027, T061 (AC-08.4) |
| Both inputs missing and the output existing: three lines, one log line | DEC-23, DEC-25 | T070 (AC-09.3) |
| An input file that exists but cannot be opened | DEC-23 | T008, T070 (AC-09.3a) |
| 1, 4 or more arguments, `-h`, `--help` | DEC-22 | T070, T072 |
| No arguments from another folder uses the project root | DEC-22 | T023 (AC-09.1) |
| `LOG_LEVEL` unset, `warn`, `info`, `INFO`, `Info`, `debug` | DEC-28 | T070 (AC-09.5) |
| At info level a stopped run logs `Run started`, never `Run ended` | DEC-28 | T047, T070 (AC-09.5) |
| `bin/run` on Windows writes CR LF to the streams | NFR-04, DEC-34 | T021 (`run_command`), T022, T041, T051, T062, T072 |
| Masking of valid numbers, other values, short and empty values | DEC-29 | T028, T047, T070 (AC-09.6), T077 (AC-06.1) |
| Error log lines name no account number | DEC-28 | T039, T070 |
| The total-check failure | DEC-24 | T059, T061 (AC-08.5) |
| An unexpected error is not caught | page 10 pick 45 | T070 |
| Exactly $0.00 left is applied | DEC-13 | T077 (AC-04.2) |
| The output file name from a fixed run time | DEC-27, DEC-30 | T026, T028 |
| An account number with leading zeros matched across both files (fixture files) | DEC-08, DEC-34 | T024, T070, T077 (AC-06.1) |

---

## Dependencies and execution order

### Phase dependencies

- **Phase 1 (Setup)**: needs `001` implemented.
- **Phase 2 (Foundational)**: after Phase 1. Blocks every user story.
- **Phase 3 (US1, MVP)**: after Phase 2. Builds the happy path of every class and `bin/run`.
- **Phase 4 (US2)**: after Phase 3.
- **Phase 5 (US3)**: after Phase 3; it can run before or after Phase 4, but both edit `runner_spec.rb`, `runner.rb` and `lib/application/errors.rb`, so run them one after the other.
- **Phase 6 (US4)**: after Phase 5 (AC-08.2 needs rejections; the stopping-error list grows in order).
- **Phase 7 (US5)**: after Phase 6 (AC-09.4 and the full stopping-error list).
- **Phase 8 (US6)**: after Phases 4 and 5.
- **Phases 9 and 10 (US7, US8)**: after Phase 8.
- **Phase 11 (Polish)**: last.

### Within each phase

- The fixture and helper tasks first, then the spec tasks, then the run that shows them failing, then the code, then the run that shows them passing.
- `spec/infrastructure/runner_spec.rb`, `spec/application/process_daily_transfer_spec.rb`, `lib/infrastructure/runner.rb` and `lib/application/process_daily_transfer.rb` are edited by one task at a time.
- In Phase 2, `display_path.rb` (T017) comes before `errors.rb` (T013), whose messages use it (plan P11); `errors.rb` and `row.rb` (T013, T014) come before `csv_rows.rb` (T015), which comes before the readers (T016).
- In Phase 3, `LoadBalances`, `DayResult` and the writer (T030 to T032) come before `ProcessDailyTransfer` (T034), which comes before `Runner` (T035) and `bin/run` (T036).

### Parallel opportunities

- Phase 1: T002 and T004 in parallel with T001.
- Phase 2: the fixtures and the five spec files T006 to T011 in parallel; then T017 and T014 in parallel, then T013, then T015, then T016, then T017a.
- Phase 3: T018, T019, T020 in parallel; T024 to T028 in parallel; then T030 to T033 in parallel.
- Phase 4: T038, T039, T040 in parallel.
- Phase 5: T047 to T051 in parallel; T055 in parallel with T054.
- Phase 6: T058 to T061 in parallel; T064 and T065 in parallel.
- Phase 7: T070 to T072 in parallel.

## Parallel example: Phase 3 (User Story 1)

```text
Task: "Write spec/application/load_balances_spec.rb, the valid file (T024)"
Task: "Write spec/application/day_result_spec.rb, applied results (T025)"
Task: "Write spec/infrastructure/final_balances_csv_writer_spec.rb, the happy path (T026)"
Task: "Write spec/infrastructure/report_printer_spec.rb, applied rows and the output path (T027)"
Task: "Write spec/application/process_daily_transfer_spec.rb, the completed day (T028)"
```

## Implementation strategy

### MVP

The MVP is the end of Phase 3: `bin/run` on the challenge's sample files gives the exact report, the exact final balances (4820.50, 9974.40, 1550.00, 1725.60, 48679.50; total 66750.00 before and after) and exit status 0, through every layer.

### Incremental delivery

1. Phases 1 and 2: the sample copies, and both files read with every file-level rule.
2. Phase 3: the sample run works end to end (US1).
3. Phase 4: a bad balances file is reported in full and stops the run (US2).
4. Phase 5: bad transfers are rejected with one reason each; empty or broken transfers files stop the run (US3).
5. Phase 6: the total check and the writer's failure rules (US4).
6. Phase 7: arguments, start checks, `LOG_LEVEL` and every exit status (US5).
7. Phase 8: every domain scenario through the runner (US6).
8. Phases 9 to 11: the design review, the suite checks and the final checks; `003` can start.

## Notes

- `[P]` tasks touch different files and depend on no unfinished task.
- Commit after each task or small group of tasks, naming what it covers.
- Never weaken a test or change an expected message, line or balance to match the code; they come from the spec and page 2.
- The domain (`lib/domain/`) is `001`'s and is not changed here; if a domain behaviour seems wrong, stop and report it.
