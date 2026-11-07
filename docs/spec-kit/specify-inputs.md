# Spec Kit command inputs

The input given to each `/speckit-*` command in the Spec Kit run, as described in the [Spec Kit brief](spec-kit-brief.md) (rule 7). Each section holds the text passed to the command, and for `/speckit-clarify` the questions and the answers chosen.

Back to the [run report](implementation-run-report.md).

## Constitution

### `/speckit-constitution`

```text
Project name: Mable Back End Code Challenge. Version 1.0.0, ratified 2026-11-07, last amended 2026-11-07.

Write lasting principles only, in plain, clear English, taken from the design decisions and the assessment rubric in docs/challenge/MABLE_BACK_END_CODE_TEST.md. The detailed rules stay in docs/design-analysis/design-decisions.md (DEC-01 to DEC-38); the constitution points to it and does not copy them.

Principles:
1. Domain models encapsulate their own rules. Each rule lives in the model it belongs to (account number, money, transfer, account, repository), with plain domain names and no ceremony (DEC-30, DEC-31).
2. Separation of concerns. Reading files, the domain and the output are kept apart, in the domain, application and infrastructure layers. The domain knows no file, clock or terminal (DEC-30).
3. Short, readable methods. Code reads as the domain; RuboCop with rubocop-rspec reports zero offences (DEC-36).
4. Tests first. Every behaviour is specified by a failing RSpec spec before the code is written. Specs are orthogonal (each rule tested once, at the level where it lives) and explain the behaviour (DEC-34).
5. Check everything before any balance changes. A transfer is all or nothing; a stopped run writes nothing (DEC-12, DEC-18, DEC-25).
6. Money exact to the cent. BigDecimal inside a Money model, never floating point, never rounded or truncated (DEC-09).
7. No over-engineering. Build only what the decisions describe; nothing out of scope (DEC-02, DEC-03, out-of-scope list).
8. Standard output for results only. The report goes to stdout; errors, usage and log lines go to stderr; exit status 0 for a completed run, 1 for a stopped run (DEC-25, DEC-26, DEC-28).

Technology constraints, only those the decisions fix: Ruby, the latest 3.4.x release; RSpec; Bundler with a committed Gemfile.lock; runtime code uses the Ruby standard library only (csv, bigdecimal and logger listed in the Gemfile); development gems rspec, simplecov, rubocop and rubocop-rspec; no other gems, no framework, no logging library beyond Ruby's standard Logger (DEC-01, DEC-28, DEC-36).

Governance: precedence is design-decisions.md, then the solution design in docs/solution-design/, then the Spec Kit files (this constitution, specs, plans, tasks). A later document that contradicts an earlier one is pointed out and resolved by changing the earlier source first, never quietly. Decisions change only with the developer's confirmation. Every plan has a Constitution Check against these principles. Amendments use semantic versioning.
```

## 001-domain

### `/speckit-specify`

```text
Spec 001-domain, short name "domain": the first of the three specs in the Spec Kit brief (docs/spec-kit/spec-kit-brief.md, rule 3). The feature directory is specs/001-domain.

Sources, in order of precedence: docs/design-analysis/design-decisions.md (DEC-01 to DEC-38, the source of truth); the solution design pages 02 (FR-03 to FR-06), 03, 05, 06 (domain components), 07.1 and 07.3 to 07.6, 08.1, 08.2, 09 (time and space, testing strategy) and 10 (traceability and glossary); CLAUDE.md; the constitution.

Owns exactly these requirements, and no others: FR-03 Apply a transfer, FR-04 A transfer that would take an account below $0, and exactly $0, FR-05 A transfer naming an account that is not loaded, FR-06 Validation of account numbers and amounts, NFR-01 Money accuracy, NFR-02 Cost of each operation, NFR-05 Code organisation and readability.

Builds:
- The project skeleton: Gemfile (runtime csv, bigdecimal, logger; development rspec, simplecov, rubocop, rubocop-rspec), committed Gemfile.lock, .ruby-version with the latest Ruby 3.4.x, the folder layout (domain, application, infrastructure; specs mirror the code), RSpec set up with random order and documentation format, SimpleCov with no minimum, RuboCop with its default settings and rubocop-rspec, and .gitignore (coverage/ and output/) (DEC-01, DEC-27, DEC-30, DEC-34, DEC-36).
- The domain: AccountNumber, Money, Account, Transfer, TransferResult, AccountRepository (add, include?, find, all), TransferService, and the domain errors InvalidAccountNumber, InvalidAmount, SameAccount, NegativeBalance, UnknownAccount, DuplicateAccount, InsufficientFunds (DEC-08 to DEC-10, DEC-13, DEC-16 to DEC-19, DEC-30, DEC-31).

User stories:
1. A valid transfer moves the money, all or nothing; a rejected transfer changes nothing; two equal transfers are both applied (FR-03; DEC-13, DEC-14, DEC-16, DEC-18, DEC-19).
2. A transfer that would leave the paying account below $0.00 is refused; one that leaves exactly $0.00 is applied; an account at $0.00 cannot pay anything (FR-04; DEC-10, DEC-13).
3. A transfer naming an account that is not loaded is refused and no account is ever created (FR-05; DEC-17, DEC-31).
4. Only 16-digit account numbers, kept as text, and only amounts in the exact money format are accepted, never rounded; a transfer amount must be above $0; a starting balance may be $0.00 but not negative (FR-06; DEC-08, DEC-09, DEC-10).
5. The repository keeps the accounts in load order, says whether a number is already held, refuses a duplicate and finds an account in the same time however many there are (supports FR-01, which 002 owns; NFR-02; DEC-11, DEC-12, DEC-31).
6. Money stays exact to the cent after any number of additions and subtractions and is always written with 2 decimal places (NFR-01; DEC-09).
7. A developer can install, test and style-check the project from the skeleton, with the tests in random order, a coverage report and zero style offences (NFR-05; DEC-01, DEC-30, DEC-34, DEC-36).

Each acceptance scenario gives two views: the domain outcome that 001 tests by calling the domain directly (the result, the error class and its exact message, and that no balance changes after every failure), and the run outcome from page 2, with standard output, standard error and the exit code stated separately and copied character for character from page 2 and page 9. Spec 002 runs the page 2 scenarios through the runner; it does not own them.

Rules:
- Names and members exactly as on page 6 and in the page 10 glossary.
- The domain owns the exact message text of every domain error; the messages that page 2 shows after "Line N: " are the domain messages, character for character. Where page 2 shows no message for an error, choose a short wording and list it under "Decided in the run".
- The domain knows no file, clock, terminal, logger or line number.
- FR-01, FR-02 and FR-08 are owned by 002; the domain rules behind them (NegativeBalance, DuplicateAccount, include?, all, TransferResult) are built and unit-tested here.
- No new behaviour and nothing out of scope on page 4. No gems beyond those the decisions name.
- Cite the FR or NFR and the DEC IDs on every requirement and scenario.
- Decide small gaps consistently with design-decisions.md and list them in a "Decided in the run" section. Leave no [NEEDS CLARIFICATION].
```

### `/speckit-clarify` (001-domain)

Pending.

### `/speckit-plan` (001-domain)

Pending.

### `/speckit-tasks` (001-domain)

Pending.

## 002-file-runner

### `/speckit-specify`

```text
Spec 002-file-runner, short name "file-runner": the second of the three specs in the Spec Kit brief (docs/spec-kit/spec-kit-brief.md, rule 3). The feature directory is specs/002-file-runner. It builds on the finished 001-domain spec and uses its domain classes, errors and messages exactly as specs/001-domain/spec.md and page 6 name them.

Sources, in order of precedence: docs/design-analysis/design-decisions.md (DEC-01 to DEC-38, the source of truth); the solution design pages 02 (FR-01, FR-02, FR-07 to FR-09, and every scenario for the runner tests), 03, 05, 06, 07 (all), 08.3 to 08.6, 09 and 10 (traceability and glossary); CLAUDE.md; the constitution.

Owns exactly these requirements, and no others: FR-01 Load the balances file, FR-02 Read the transfers file, FR-07 The order transfers are applied in, FR-08 The end-of-day result and its output, FR-09 The runner, NFR-03 Scale, NFR-06 Testability and coverage.

Builds:
- The application layer: LoadBalances, ProcessDailyTransfer, DayResult, and the run-stopping errors InvalidBalancesFile, NoTransfers and TotalChanged (DEC-11, DEC-12, DEC-15, DEC-16, DEC-19 to DEC-21, DEC-24, DEC-26, DEC-28 to DEC-31).
- The infrastructure layer: BalancesCsvReader, TransfersCsvReader, FinalBalancesCsvWriter (with the class method default_path), ReportPrinter, Runner, and the run-stopping errors UnreadableFile and OutputNotWritable; and bin/run (DEC-04 to DEC-07, DEC-22 to DEC-29, DEC-32).
- The data/ copies of the two sample files that bin/run uses with no arguments (DEC-22), and the test fixtures DEC-34 lists.
- The five end-to-end runs of bin/run (NFR-06; DEC-34, DEC-35): the challenge sample files with the exact closing balance of every account (4820.50, 9974.40, 1550.00, 1725.60, 48679.50, total 66750.00 before and after), mixed rejections, all rejected, an invalid balances file, and a wrong number of arguments.
- Every page 2 scenario run through the runner with real CSV files and exact standard output, standard error and exit status, including the scenarios of FR-03 to FR-06, which 001 owns; 002 runs them but does not own them (brief rule 4).

User stories:
1. A user runs the challenge's sample files with bin/run and no arguments and gets the exact report, the exact output file and exit status 0 (FR-08, FR-09; DEC-22, DEC-26, DEC-27, DEC-35).
2. The balances file is loaded in full, accepting common CSV forms; an invalid or empty balances file stops the run, listing every problem with its line number (FR-01; DEC-04 to DEC-12, DEC-31).
3. The transfers file is read one row at a time in file order; a bad row is rejected with one reason and the run continues; an empty file or a file that cannot be read past a line stops the run (FR-02, FR-07; DEC-04 to DEC-07, DEC-14 to DEC-16, DEC-19 to DEC-21, DEC-32).
4. A completed run checks the total, writes the final balances to a new CSV file that is never overwritten, then prints the report (FR-08; DEC-24, DEC-26, DEC-27).
5. The runner takes 0, 2 or 3 arguments, checks the files together before reading anything, logs at the LOG_LEVEL level with masked account numbers, prints a clear message for every stopped run and exits with 0 or 1 (FR-09; DEC-02, DEC-03, DEC-22, DEC-23, DEC-25, DEC-28, DEC-29).
6. Every page 2 scenario of FR-03 to FR-06 gives its exact run outcome through the runner (run, not owned, here).
7. The run's cost grows only with the rows in the two files, and nothing is kept between runs (NFR-03; DEC-03, DEC-32).
8. The tests run in random order, test each rule once where it lives, do not depend on the clock or the terminal, prove the total-check failure, and measure coverage (NFR-06; DEC-24, DEC-28, DEC-30, DEC-34, DEC-36).

Each acceptance scenario states standard output, standard error and the exit status separately, copied character for character from page 2 and page 9's message table. Where page 2 shows only part of a stream, the rest is built from the FR-08 report layout, the AC-09.6 masking rule and DEC-21, marked as derived, adding no behaviour.

Rules:
- Names and members exactly as on page 6 and in the page 10 glossary; domain names and messages exactly as in specs/001-domain/spec.md.
- The domain owns the exact text of every domain error; LoadBalances and the Runner only add what page 2 and page 9 show them adding (the line number, the duplicate's first line, the header hint, the "Error: " prefix, the log line).
- No new behaviour and nothing out of scope on page 4. No gems beyond those the decisions name.
- Cite the FR or NFR and the DEC IDs on every requirement and scenario.
- Decide small gaps consistently with design-decisions.md and list them in a "Decided in the run" section. Leave no [NEEDS CLARIFICATION].
```

### `/speckit-clarify` (002-file-runner)

Pending.

### `/speckit-plan` (002-file-runner)

Pending.

### `/speckit-tasks` (002-file-runner)

Pending.

## 003-delivery

### `/speckit-specify`

Pending.

### `/speckit-clarify` (003-delivery)

Pending.

### `/speckit-plan` (003-delivery)

Pending.

### `/speckit-tasks` (003-delivery)

Pending.

## Whole specification

### `/speckit-analyze`

Pending.
