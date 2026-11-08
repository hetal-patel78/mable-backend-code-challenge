# Spec Kit run report

The record of the Spec Kit run described in the [Spec Kit brief](spec-kit-brief.md). It is updated after every step.

Back to [project instructions](../../CLAUDE.md).

## Part 1: Specification

Started by [P24](../prompts/prompts-spec-creation-phase.md#p24), from the branch `spec-kit-setup`. Every review in Part 1 (each per-spec review round, the cross-check and the review before `main` is pushed) is done by an independent Claude Opus 5.5 agent that did not write or fix what it reviews ([P25](../prompts/prompts-spec-creation-phase.md#p25)); the reviewer model is recorded for each round.

**Status: Specification ready for review.**

### Status

| Step | State |
|---|---|
| 1. Start | Done |
| 2. Constitution | Done |
| 3. Specs | Done |
| 4. Clarify, plan and tasks | Done: 001 7 rounds (2 earlier, 5 continuation), 002 10 rounds (1 earlier, 9 continuation), 003 26 rounds (12 earlier, 14 continuation); each ended on a round with 0 defects. All three spec branches pushed: 001-domain, 002-file-runner, 003-delivery |
| 5. Cross-check | Done: 3 rounds (round 1 found 1 medium defect, round 2 found 2 low, round 3 found 0 and was clean) |
| 6. Scripted checks | Done: 3 rounds (round 1 failed 3 checks, round 2 failed 1, round 3 passed all 7) |
| 7. Merge and push | Done: the three spec branches merged into `spec-kit-specs` with their small commits kept (no squash) and `spec-kit-specs` pushed. An independent review by Claude Opus 5.5 approved everything going to `main` in round 6 (rounds 1 to 5 found 6 defects in total, all fixed), and `main` was then pushed as a fast-forward to `spec-kit-specs` |
| 8. Stop | Done: Specification ready for review |

### Check results

Step 4 reviews. Every round is by an independent Claude Opus 5.5 agent that did not write or fix the spec. Continuation rounds are numbered after each spec's earlier rounds, with the continuation number in brackets.

| Spec | Round | Reviewer | Defects found | Result |
|---|---|---|---|---|
| 001-domain | 1 | Claude Opus 5.5 (independent) | 7 (2 medium, 5 low) | All 7 fixed |
| 001-domain | 2 | Claude Opus 5.5 (independent) | 3 (1 high, 1 medium, 1 low) | 2 fixed; R2-01 (high) was not a defect (see below) |
| 001-domain | 3 (continuation 1) | Claude Opus 5.5 (independent) | 1 (high) | Fixed |
| 001-domain | 4 (continuation 2) | Claude Opus 5.5 (independent) | 3 (1 medium, 2 low) | Fixed |
| 001-domain | 5 (continuation 3) | Claude Opus 5.5 (independent) | 1 (medium) | Fixed |
| 001-domain | 6 (continuation 4) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 001-domain | 7 (continuation 5) | Claude Opus 5.5 (independent) | 0 | Converged |
| 002-file-runner | 1 | Claude Opus 5.5 (independent) | 7 (1 high, 1 medium, 5 low) | 6 fixed; R1-01 (DEC-36 conflict) was not a defect (see below) |
| 002-file-runner | 2 (continuation 1) | Claude Opus 5.5 (independent) | 7 (1 high, 3 medium, 3 low) | Fixed |
| 002-file-runner | 3 (continuation 2) | Claude Opus 5.5 (independent) | 3 (2 high, 1 low) | Fixed |
| 002-file-runner | 4 (continuation 3) | Claude Opus 5.5 (independent) | 3 (1 medium, 2 low) | Fixed |
| 002-file-runner | 5 (continuation 4) | Claude Opus 5.5 (independent) | 2 (2 low) | Fixed |
| 002-file-runner | 6 (continuation 5) | Claude Opus 5.5 (independent) | 3 (1 high, 2 medium) | Fixed |
| 002-file-runner | 7 (continuation 6) | Claude Opus 5.5 (independent) | 3 (3 medium) | Fixed |
| 002-file-runner | 8 (continuation 7) | Claude Opus 5.5 (independent) | 3 (2 medium, 1 low) | Fixed |
| 002-file-runner | 9 (continuation 8) | Claude Opus 5.5 (independent) | 1 (medium) | Fixed |
| 002-file-runner | 10 (continuation 9) | Claude Opus 5.5 (independent) | 0 | Converged |
| 003-delivery | 1 | Claude Opus 5.5 (independent) | 5 (4 medium, 1 low) | 5 fixed |
| 003-delivery | 2 | Claude Opus 5.5 (independent) | 3 (1 medium, 2 low) | 3 fixed |
| 003-delivery | 3 | Claude Opus 5.5 (independent) | 5 (1 high, 1 medium, 3 low) | 5 fixed |
| 003-delivery | 4 | Claude Opus 5.5 (independent) | 7 (3 medium, 4 low) | 7 fixed |
| 003-delivery | 5 | Claude Opus 5.5 (independent) | 6 (2 medium, 4 low) | 6 fixed |
| 003-delivery | 6 | Claude Opus 5.5 (independent) | 3 (3 medium) | 3 fixed |
| 003-delivery | 7 | Claude Opus 5.5 (independent) | 4 (1 medium, 3 low) | 4 fixed |
| 003-delivery | 8 | Claude Opus 5.5 (independent) | 3 (3 low) | 3 fixed |
| 003-delivery | 9 | Claude Opus 5.5 (independent) | 1 (medium) | Fixed |
| 003-delivery | 10 | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 11 | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 12 | Claude Opus 5.5 (independent) | 2 (1 medium, 1 low) | Fixed; re-reviewed in continuation 1 |
| 003-delivery | 13 (continuation 1) | Claude Opus 5.5 (independent) | 5 (1 medium, 4 low) | Fixed |
| 003-delivery | 14 (continuation 2) | Claude Opus 5.5 (independent) | 2 (1 medium, 1 low) | Fixed |
| 003-delivery | 15 (continuation 3) | Claude Opus 5.5 (independent) | 1 (medium) | Fixed |
| 003-delivery | 16 (continuation 4) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 17 (continuation 5) | Claude Opus 5.5 (independent) | 1 (high) | Fixed |
| 003-delivery | 18 (continuation 6) | Claude Opus 5.5 (independent) | 3 (1 medium, 2 low) | Fixed |
| 003-delivery | 19 (continuation 7) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 20 (continuation 8) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 21 (continuation 9) | Claude Opus 5.5 (independent) | 1 (medium) | Fixed |
| 003-delivery | 22 (continuation 10) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 23 (continuation 11) | Claude Opus 5.5 (independent) | 2 (1 medium, 1 low) | Fixed |
| 003-delivery | 24 (continuation 12) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 25 (continuation 13) | Claude Opus 5.5 (independent) | 1 (low) | Fixed |
| 003-delivery | 26 (continuation 14) | Claude Opus 5.5 (independent) | 0 | Converged |

Each spec ended on a round with 0 defects. The `001-domain`, `002-file-runner` and `003-delivery` branches were pushed.

RuboCop `Metrics/BlockLength` against spec files, the blocker in the earlier 001 and 002 rounds, was not a defect: rubocop-rspec's default config already excludes spec files, so no DEC-36 change was needed.

Step 5 cross-check. Every round is by an independent Claude Opus 5.5 agent that did not write or fix the specs. Round 1 found one medium defect, round 2 found two low defects, all fixed, and round 3 found none, so the cross-check ended on a clean round.

| Round | Reviewer | Defects found | Result |
|---|---|---|---|
| 1 | Claude Opus 5.5 (opus), independent | 1 (medium) | Fixed |
| 2 | Claude Opus 5.5 (opus), independent | 2 (2 low) | Fixed |
| 3 | Claude Opus 5.5 (opus), independent | 0 | Converged |

Step 6 scripted checks. The table shows the final round (round 3). Round 1 failed three checks (exact strings, channels and exit codes, and placeholders) and round 2 failed one (exact strings); all were fixed before round 3.

| Check | Result | Detail |
|---|---|---|
| FR/NFR coverage | Passed | 15 IDs (FR-01 to FR-09, NFR-01 to NFR-06), each owned by one spec and in its spec.md and at least one task. Thinnest: FR-05 and NFR-04, one task each. 0 failures |
| Exact strings | Passed | 41 acceptance criteria; 119 unique output strings (120 string-by-spec pairs), all exact; 28 exit-code checks, all matched. 0 failures |
| Channels and exit codes | Passed | 70 run-output scenarios of 100 each state standard output, standard error and exit status separately. 8 unit-level scenarios not applicable. 0 failures |
| Names match page 6 and page 10 | Passed | 29 names, all found in plan.md or data-model.md; 6 new names declared in their spec's Decided list. 0 failures |
| Edge cases have planned tests | Passed | 61 of 61 edge cases matched to tasks. 0 failures |
| No code | Passed | 0 files under lib/, bin/ or spec/ in git. 0 failures |
| No placeholders | Passed | 28 files scanned; 0 placeholders, 0 TODO, 0 TBD. 0 failures |

`/speckit-analyze` counts by severity per spec, analyzer Claude Opus 5.5 (opus). Specs are in the order 001-domain, 002-file-runner, 003-delivery. No critical or high issues in any round.

| Spec | Round | Critical | High | Medium | Low |
|---|---|---|---|---|---|
| 001-domain | 1 | 0 | 0 | 0 | 3 |
| 001-domain | 2 | 0 | 0 | 0 | 7 |
| 001-domain | 3 | 0 | 0 | 0 | 2 |
| 002-file-runner | 1 | 0 | 0 | 2 | 4 |
| 002-file-runner | 2 | 0 | 0 | 3 | 6 |
| 002-file-runner | 3 | 0 | 0 | 2 | 6 |
| 003-delivery | 1 | 0 | 0 | 3 | 5 |
| 003-delivery | 2 | 0 | 0 | 1 | 4 |
| 003-delivery | 3 | 0 | 0 | 1 | 4 |

Step 7 review before pushing `main`. Every round is by an independent Claude Opus 5.5 agent that did not write or fix the changes. Brief step 7 pushes `spec-kit-specs` first and then `main` after this review approves. At the time of round 1, `spec-kit-specs` was not pushed and `origin/main` was unchanged; each push and the approval are recorded here only once they happen.

| Round | Reviewer | Defects found | Result |
|---|---|---|---|
| 1 | Claude Opus 5.5 (opus), independent | 1 (medium: this report stated the step 7 pushes and an approval before they happened) | Fixed |
| 2 | Claude Opus 5.5 (opus), independent | 2 | Fixed |
| 3 | Claude Opus 5.5 (opus), independent | 1 (this report did not record round 2) | Fixed |
| 4 | Claude Opus 5.5 (opus), independent | 1 (this report did not record round 3) | Fixed |
| 5 | Claude Opus 5.5 (opus), independent | 1 (this report did not record round 4) | Fixed |
| 6 | Claude Opus 5.5 (opus), independent | 0 | Approved |

After round 6 approved, the only change was the commit that records the approval and the pushes in this report. A further independent Claude Opus 5.5 agent checked that commit before `main` was pushed.

### Decided in the run

- **Constitution**
  - Two extra sections, "Technology Constraints" and "Development Workflow", added to the template. The workflow section restates the brief's rule 5.
  - Principle V: an invalid balances file is found in full before any transfer runs, and a run that stops writes no output file. The unchanged total of all balances is under this principle too.
  - Principle VIII: exit statuses 0 and 1 are part of the output-channel principle. The usage message goes to stderr with errors and logs.
  - Governance: a departure from a principle needs justification in the plan. Design reasoning goes in the README, not in code comments. CLAUDE.md is the runtime guidance file.
- **001-domain**
  - Code lives under `lib/`, starting with `lib/domain/`.
  - Money error messages say "balance" for an opening balance and "amount" for a transfer amount. The domain owns this text.
  - Money keeps the text it was built from, so `-0` stays `-0`.
  - Text with a point and 3 or more decimals gets "has more than 2 decimal places". Other bad text gets "is not a valid amount".
  - The error messages for a zero or negative amount, same account, unknown account, duplicate account and insufficient funds are fixed in the spec.
  - When both accounts are unknown, the error names the from account.
  - The six reason codes are defined once in the domain.
  - Where page 2 gives no full output, the lines are marked "(derived)".
  - Each single-row example is the only row of `transfers.csv`, on line 1.
  - The exact Ruby 3.4.x version is set by the plan, not the spec.
  - A `TransferResult` keeps every field of its row, in order, after trimming. A malformed row gives "N fields, expected 3", and the log takes from, to and amount by position.
  - `AccountNumber.new(text)` has `to_s` for the full text and compares by text (`==`, `eql?`, `hash`), with no other reader.
  - Money equality and comparison use the amount only, so -0 equals 0. The written minus sign only decides whether a value counts as negative. A Money made by adding or taking away is negative only when its amount is below 0.
  - `Account#withdraw` and `#deposit` do not check that the amount is above $0. That rule stays in `Transfer`, which `TransferService` relies on.
  - Ruby 3.4.12 goes in `.ruby-version`, the highest 3.4.x release on 2026-11-08.
  - No namespace module: every class and error is a top-level constant with its page 6 name. The seven errors are in `lib/domain/errors.rb`, each a direct `StandardError` subclass with no spec file of its own, and each is tested where it is raised.
  - `Money.amount(text)` and `Money.balance(text)` set the word "amount" or "balance" in the messages. Money members are `text`, `to_s`, `+`, `-`, `<=>` (with `Comparable`), `==`, `eql?`, `hash`, `negative?`, `positive?`, and `Money.new(value, text = nil)`.
  - `Account.new(number, balance)` and `Account.check_opening_balance(balance)`, which raises `NegativeBalance`. `Transfer.new(from:, to:, amount:)` takes keywords.
  - `TransferResult.applied(line_number:, fields:)` and `.rejected(line_number:, fields:, reason:, header_hint: nil)`. `REASON_CODES` is a frozen list of symbols in DEC-19 order, and an unknown reason raises `ArgumentError`. 002 supplies the header hint text. `TransferService.new(repository)` and `#apply(transfer)` return nil.
  - Files load their own dependencies with `require_relative`. The Gemfile lists the runtime gems at top level and the four tools in group `:development, :test`, with no version constraints and no ruby line. Gemfile.lock pins the platforms x86_64-linux and x64-mingw-ucrt, and 003 completes the list.
  - `.rubocop.yml` holds only `plugins: [rubocop-rspec]`. Every file has a frozen_string_literal comment and each class a one-line comment, because RuboCop's defaults require both.
  - Specs follow rubocop-rspec defaults, with one expectation per example. A helper `attempt(error_class)` rescues only the named error. "Deposit is never called" is proven by the receiving balance staying unchanged, not by a spy.
  - `AccountNumber`, `Money`, `Transfer` and `TransferResult` freeze when built. SimpleCov starts at the top of `spec_helper`, filtering `/spec/`.
  - An error with one message form builds its message from its values, for example `DuplicateAccount.new(account_number)`. `InvalidAmount` takes the full message because it has four forms.
  - Tasks follow code dependency (US4, US6, US2, US5, US3, US1), not priority. Each error and test builder is added in the phase whose test first needs it. The service-level views of AC-04.x, AC-05.x and US6 scenario 4 are tested in the US1 phase, where `TransferService` is built.
  - DEC-09's own examples (100, 100.5, 100.50 valid; 100., +100, $100 invalid) are tested alongside the table rows.
- **002-file-runner**
  - Runner scenarios (`spec/infrastructure/runner_spec.rb`, grouped by FR) call `Runner` in the same process, in a temporary folder. The test writes the CSV files there, so they are not fixture files, and passes `output/final_balances_2026-11-07_143005.csv` as the third argument. This keeps the end-to-end runs at 5.
  - The five end-to-end runs are AC-08.1, AC-08.2, AC-02.3, AC-01.4 and AC-09.2 (one argument). Each runs `bin/run` as a separate process (`Open3.capture3` with `RbConfig.ruby`, `LOG_LEVEL` removed) with a temporary folder as the current folder, and passes the default output name as the third argument.
  - AC-09.1 uses a stand-in `ProcessDailyTransfer`. AC-08.4 uses `../` paths from a subfolder.
  - AC-09.7 checks `default_path` for two run times one second apart, and checks that two runs give the same output.
  - AC-08.3 also reads the AC-08.2 output back in as a balances file.
  - The count is singular for one problem: "(1 problem)" and "1 problem".
  - Each run-stopping message is the text after "Error: ". The Runner adds only that prefix and the log line.
  - A malformed transfers row with 1 field logs `Line N rejected: <masked from> malformed_row`. The report keeps "malformed_row: <K> fields, expected 3" for every count.
  - Partial criteria from page 2 are completed in the spec.
  - Tests match the reason from the system as any non-empty text.
  - The test for an unreadable file must work on every OS the suite runs on. The plan picks the method.
  - One rule shows every path in the report, the messages and the log lines. The plan picks where it lives.
  - `LOG_LEVEL` is compared in any letter case, without trimming. Anything else falls back to warn.
  - 002 creates `data/` and `spec/fixtures/sample/` with copies of the sample files. `docs/challenge/` is unchanged.
  - The start check on the output path fails only when a file exists there. An existing folder fails at writing.
  - A transfers file whose first row cannot be read stops with UnreadableFile, not NoTransfers.
  - Spaces and tabs around a value are trimmed, and those inside a value are kept. Blank lines are judged the same way.
  - The duplicate known gap applies to any first copy that is not added because of its own problem (an invalid or negative balance, or the wrong number of fields). Only the first row's problem is reported, and the run stops either way.
  - At info level, a run that passes the start checks and then stops keeps the "Run started" line and any row lines, and never logs "Run ended". A run stopped by the arguments or the start checks logs no info line.
  - A missing output folder that cannot be created raises `OutputNotWritable` with the AC-09.4 message. Folders already created are left in place.
  - The end-to-end specs turn CR LF into LF in the captured standard output and standard error, and compare the output file byte for byte (LF only).
  - A Row Data value and one `CsvRows` class hold the shared CSV rules and `HEADER_HINT`. There is no base class.
  - Both readers expose `each_row(path)` and `FIELD_COUNT` (2 or 3), and read row by row. LoadBalances reads every row before any transfer runs.
  - `LoadBalances.new(reader, repository).call(path)`. `ProcessDailyTransfer.new(run_time: Time.now, **parts)` takes exactly the six named parts, and `call(balances_path, transfers_path, output_path = nil)` returns the DayResult.
  - DayResult is a Data value with `results`, `total_before`, `total_after`, `accounts` and `output_path`, and the counts, `rejected_counts` in DEC-19 order (only the reasons that occurred), `all_rejected?`, and `ALL_REJECTED_WARNING`. The report and the run-end log count the same results.
  - Each run-stopping error builds its own message and `stop_reason`. The reason from the system is the message up to Ruby's " @ " call details.
  - `DisplayPath.of(path, folder = Dir.pwd)`, an infrastructure helper, shows a path relative to the current folder when the file is in it or below it, and in full otherwise (DEC-26). The Runner resolves each path to a real, absolute path for the start checks, then gives `ProcessDailyTransfer` the balances and transfers paths in their shown form and the output path in full, so `DayResult.output_path` holds the full path. Only `infrastructure/` uses `DisplayPath`: the Runner's start-check lines and the paths it passes on, `UnreadableFile` and `OutputNotWritable`, and `ReportPrinter`, which alone works out the shown output path. `InvalidBalancesFile.no_rows`, `NoTransfers` and the `Run started` line show the path they are given (page 6 pick 53).
  - `CsvRows` reads with `CSV.open` and one row per `csv.shift`, as DEC-32 says, because DEC-05 and DEC-07 need the raw line and the physical-line count (plan P29).
  - `Runner.new(stdout:, stderr:, env:).run(arguments)` returns 0 or 1. `ReportPrinter.new(output:, current_folder:).print(day_result)`. The logger is at info when `LOG_LEVEL` is `casecmp?('info')`, otherwise warn.
  - The writer creates missing folders with `mkdir_p`, opens the file with `WRONLY|CREAT|EXCL|BINARY`, writes LF only, and deletes the file only if it created it before raising `OutputNotWritable`.
  - An applied amount is shown and logged as `Money.amount(text).to_s`. A rejected value is shown as written, and an empty value as `""`.
  - Page 2 scenarios are in `spec/infrastructure/runner_spec.rb`, grouped by FR. The five end-to-end specs are `RSpec.describe Runner, '#run'` in `spec/acceptance/runner_run_<case>_spec.rb`, each with one inner `describe 'with <case>'` (`sample files`, `mixed rejections`, `all rejected`, `invalid balances`, `wrong arguments`), so RuboCop's default cops pass with no setting changed.
  - Test helpers are in `spec/support/` (`fakes.rb`, `files.rb`, `runs.rb`, `report_templates.rb`, and the row builders in `builders.rb`).
  - Fixture files hold only the DEC-34 cases and the end-to-end inputs. Byte-sensitive cases are written by the tests with `File.binwrite`. No `.gitattributes` file is added for them.
  - A folder at the input path is the "exists but cannot be opened" case. A fake account that raises `Errno::ENOSPC` on its second line tests the partial write. `ChangingTotalRepository` returns the real accounts on the first `all` call, and from the second, the first account with 1.00 less, giving 66750.00 to 66749.00.
  - The phases run outside-in. The User Story 6 phase adds no code.
  - The end-to-end specs use `Open3.capture3` with `RbConfig.ruby`, and `LOG_LEVEL` removed. `bin/run` calls `exit(Runner.new.run(ARGV))` and is stored with mode 100755. `Runner::STOPPING_ERRORS` lists the five run-stopping errors and nothing else is rescued. The start checks use `File.exist?` for inputs and `File.file?` for the output path.
- **003-delivery**
  - In runs made by hand or by CI, `<run time>` is the real run time. Nothing else may differ from page 2.
  - A clean checkout is a fresh clone of the pushed branch into a new empty folder outside the working repository.
  - On Windows, the Output file line uses `/`, as page 2 shows.
  - `Gemfile.lock` lists the platforms needed for a frozen install on Windows, Ubuntu CI and Docker. The plan picks the list.
  - The Docker image is named `mable-transfers`, built from the full official `ruby:<version>` image. Its working folder is the project root.
  - The README says in one line that a reviewer's own input files must be mounted into the container, like the output.
  - `bin/run` is stored executable, with a `#!/usr/bin/env ruby` line and LF line endings. Every text file uses LF.
  - The README shows the sample report exactly as in AC-08.1, with the page 2 run time.
  - The CI workflow is `.github/workflows/ci.yml`, run on push to any branch, with RSpec and RuboCop as separate steps.
  - The README lists the ten assumptions, the known limitations from pages 9 and 10, and a "How this was built" section.
  - No `.dockerignore`. The Dockerfile adds nothing beyond DEC-36.
  - The README keeps the challenge link and an updated layout table, and replaces the Status and "To be added" sections.
  - The submission branch is `main`, the default branch the submission link opens, after the merged implementation is pushed to it. The submission checks, clean checkouts and the coverage figure are taken on its latest commit.
  - No `.gitattributes` file is created, and `bin/run` is not forced to LF in checkouts. With `core.autocrlf=true` on Windows every text file, `bin/run` included, gets CRLF, which RuboCop's default `Layout/EndOfLine` expects there. A check runs `bundle exec rubocop` in a fresh `core.autocrlf=true` Windows clone and expects `no offenses detected`.
  - The Docker default command is `CMD ["ruby", "bin/run"]` in exec form, not run through `bundle exec`, so the exit status is the program's and a CRLF first line cannot stop it starting. A command after the image name replaces it, and every in-container call of the program is `ruby bin/run ...`.
  - The Docker checks run from a Linux, macOS or WSL shell, not Git Bash, which breaks the mounts. The Windows Docker checks (C-26 and C-41) run in PowerShell. C-19 creates `output/` on the host before the first mounted run.
  - The container runs as the image's default user, root, with no `--user`. The README says in one line that the output file may belong to root on a Linux host.
  - The README sections follow the order of DEC-37: build, test and run (with Ruby, on Windows and with Docker); input files; log level and exit status; assumptions; design; test coverage; storage, production items and known limitations; how this was built; repository layout; the challenge.
  - `.ruby-version` holds the bare version number, with no `ruby-` prefix. The Dockerfile's first line is `FROM ruby:` followed by the same text, and check C-04 compares them.
  - `Gemfile.lock` lists the platforms ruby, x64-mingw-ucrt, x86_64-linux, aarch64-linux, x86_64-darwin and arm64-darwin, added with `bundle lock --add-platform`. No gem versions change.
  - `.github/workflows/ci.yml` is named CI and runs on push with no branch filter. It has one job, `checks`, on ubuntu-latest, with five steps: checkout, ruby/setup-ruby (which reads `.ruby-version`), `bundle install` with `BUNDLE_FROZEN=true`, `bundle exec rspec`, and `bundle exec rubocop`. `actions/checkout@v5` and `ruby/setup-ruby@v1` are pinned to major versions. The bundler cache is not used.
  - Frozen installs use `BUNDLE_FROZEN=true` in CI, Docker and the checks, not `--frozen` or deployment mode. The README tells a reviewer to run plain `bundle install`.
  - The Dockerfile has exactly six instructions: `FROM ruby:<version>`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN bundle install`, and `CMD ["ruby", "bin/run"]`. There is no `USER` line. If the default `ruby:<version>` image lacks `/usr/share/zoneinfo`, the `-bookworm` variant is used, since installing tzdata would add a package FR-024 does not allow.
  - The README's Docker commands are: build with `docker build -t mable-transfers .`; run with `-v "$(pwd)/output:/app/output"` in a POSIX shell, or `-v "${PWD}/output:/app/output"` in PowerShell; both runs use `--rm` and `-e TZ=Australia/Sydney`. The test run is `docker run --rm mable-transfers bundle exec rspec`. There is no `--user` and no `-it`.
  - The coverage figure is SimpleCov's printed `Line Coverage` line from a full run on a clean checkout of the final code. After the push it is compared with the CI log of the latest `main` commit.
  - The README title and the challenge link keep the challenge's own name. FR-014's "no company named" is read as the company whose balances are processed.
  - The checks are commands in `quickstart.md`, with results in the run report. No script or folder is added for them. Line endings are checked with `git ls-files --eol`, and copies of the challenge files by Git blob ID, so both give the same result on a Windows checkout.
  - If `bin/run` is not stored as mode 100755, the fix is `git update-index --chmod=+x bin/run`, with no content change.
  - The Windows checks clone with `git clone -c core.autocrlf=true`, so the data files get CRLF line endings, and they use PowerShell's `$LASTEXITCODE`.
  - A clean checkout is always made with `git clone --branch $BRANCH $SRC` into a new empty folder outside the working repository. During development `$BRANCH` is the implementation branch and `$SRC` the local repository, standing in for the pushed branch. The final repeat runs on a fresh clone of `origin` `main` after the push. If no Linux or macOS machine is available, US1's checks run in one official `ruby:<version>` container with the clean checkout mounted, and the run report says so.
  - The CI run is checked on the pushed implementation branch and again on `main`. If the code changes after the coverage figure was taken, the figure is updated and C-33 is repeated.

### Changed in the run

Each change is its own "Run change:" commit, made under brief rule 5 after the [independent review after Part 1](#independent-review-after-part-1), following the chain decision, solution design, specs.

- **Page 02 AC-08.4** (`197caa9`): from the project root the last report line is `Output file: output/final_balances_2026-11-07_143005.csv`; from `docs` the output file is outside the run folder, so the line shows its full path, `<project root>/output/final_balances_2026-11-07_143005.csv`, as [DEC-26](../design-analysis/design-decisions.md#dec-26) says. DEC-26 itself is unchanged.
- **DEC-32** (`5ce0b1a`): the transfers file is read one row at a time with Ruby's CSV library (`CSV.open`, one row per `shift`), so the physical line number of each row is kept ([DEC-07](../design-analysis/design-decisions.md#dec-07)). The solution design did not name the method, so it is unchanged.
- **Page 06 and page 10** (`bb2f85c`): the infrastructure helpers `CsvRows`, `Row` and `DisplayPath` are added to page 06, the page 10 components glossary and the assistant's picks (picks 52 and 53). The `Runner` passes `ProcessDailyTransfer` the balances and transfers paths in their shown form and the output path in full, so no application class works out a shown path.
- **Page 10 pick 53** (`eceb4ee`): the reason now names the dependency actually removed, `infrastructure/display_path`, and names picks 33 and 35 as the only application-to-infrastructure uses left.

An early review claimed RuboCop could not reach zero offences under DEC-36; that was false, because rubocop-rspec's default configuration already excludes spec files from Metrics/BlockLength, so DEC-36 was not changed.

### Fixed in review

- **001-domain**
  - Money equality, `eql?` and `hash` now agree across the plan, research, data model and tasks.
  - Acceptance scenarios that lacked a standard output, error or exit statement now have one (US1, US3, US5 and US6).
  - Money comparison tests now follow the test-first rule (constitution IV).
  - AC-03.2 and T040 now state the domain outcome, and the domain API table has its blank line restored.
  - `lib/domain/errors.rb` now has a task.
  - Task references to AC-05.3 are corrected.
  - Removed the false RuboCop `Metrics/BlockLength` claim from research R3 (see Check results).
  - Task T040 and the DEC-13 edge-case row now test AC-04.1, AC-04.3, AC-05.1, AC-05.2 and both unknown-account cases.
  - Plan decisions and design overview record the AccountNumber name, as brief rule 5 requires where page 10 leaves a name open.
  - Quickstart step 3's expected end of the `bundle exec rspec` output corrected.
  - AC-03.3's third scenario, its edge case and its related task corrected.
  - Money's `text` member matches across the data model, tasks T018 and T023, plan D5 and research R7.
- **002-file-runner**
  - The false RuboCop limit claim in research R8 is removed; no DEC-36 change is needed.
  - AC-08.3, AC-09.7 and US5 now state the standard output, error and exit code, and T061 matches.
  - The DisplayPath rule is the same in FR-029, the edge cases, plan P10, the data model and the command-line contract.
  - T070's line count, the US6 build-order sentence and the checklist's item count are corrected.
  - The test helper signatures in research R9 match tasks T019 and T021.
  - Research R1, plan P11 and the components contract agree on the row-by-row read, line-number handling for multi-line examples and what the parts expect of each other.
  - The `run_scenario` defaults (T021, AC-01.3 to AC-01.10) match the tasks that use them, and the fake reader and unreadable-file tests (T019, T028, T038) agree.
  - Plan P19, its source tree and the end-to-end tasks agree on where the five runs live; scenarios that must run through the runner (AC-08.4, AC-09.5, AC-09.7) are corrected, per brief rule 4.
  - Plan P24's phase rule, the phase checkpoints (after T017 and T078) and the test order in Phases 3, 4, 5 and 7 (T031, T045, T052, T073) now follow constitution IV and brief rule 5; T059 no longer rescues `TotalChanged` in a `before` block.
  - US5 scenarios 1 and 6, the AC-09.5 variants, the AC-08.3 third argument and the AC-08.4 scenarios now state standard output, error and exit code, and their tasks match.
  - The components contract's loading table (two rows) and the checklist's item count are corrected.
- **003-delivery**
  - Windows check commands: byte-for-byte stream comparison, `$env:CHECKS`, `$REPO`, `$LASTEXITCODE`, clone paths and output redirection.
  - Docker checks: the README-command check (C-41), C-29 run as written, the Dockerfile first-line check, the C-21 redirect, the fresh-checkout folders, and the expected output folder.
  - The container fallback for Phase 4, used when no Linux or macOS machine is available, is written out in full.
  - Acceptance scenarios now state the standard output, error and exit code (US1 to US5), and the Docker build log is not compared exactly.
  - Requirements and tasks: FR-019 has a task, FR-014's wording is the same in the spec, plan, contracts and data model, and the FR-025(c) and SC-001 wording and the Key Entities list match.
  - Check counts in the plan match `quickstart.md`, and the commands for C-01, C-28, C-40 and C-42 are corrected.
  - Tasks: phase checkpoints, the Spec Kit task ID format, the Phase 9 order, the T006 vs FR-030 mismatch, and the coverage update wording in T050.
  - Repository files: the pushed `main` must be tracked, and the contract's "nothing more" list matches the spec.
  - `bin/run` shebang, LF line endings, the `.gitattributes` rule and the renormalise step in T006 are consistent across FR-018, the data model, the research, Decided item 16 and tasks T004 to T008 and T058.
  - The `bin/run` edge case ("on Linux, macOS and in Docker") and Decided item 16 corrected.
  - C-29, US5 scenario 2 and T047 cover the README's two- and three-argument forms.
  - FR-021 and the CI workflow contract (step 1, the "must not" list, plan item 3) and US4 scenario 3 agree on the steps the workflow may contain.
  - C-05 and FR-016 match NFR-04's standard-library limit for the program itself.
  - The repository-files contract's "nothing more" list and the plan's Scale/Scope match FR-030 and SC-007.
  - The spec's "Sources and ownership" (Builds on) and the plan's scope wording are corrected.
  - Plan, research and checklist state the spec's item counts correctly; the rejected alternatives in plan item 3 and research R-2 and R-5 are corrected, including R-5's CI matrix citation.
  - US2 scenario 4 and US4 scenario 2 now state standard output, error and exit code.
  - Quickstart expected texts and checks C-21, C-23 and C-26 compare a run's output the same way.
- **Cross-check**
  - The Gemfile.lock platform list in 001 plan D14 and in 003's Decided list now agree (X1).
  - 001 no longer gives a run outcome for a scenario that no spec runs, since its spec says every run outcome goes through the 002 runner (XC2-01).
  - 003's example Ruby version is now 3.4.12, the version 001 pins in plan D1 and task T001 (XC2-02).
- **Before merge**
  - The Phase dependencies section of tasks.md now says Phase 5 follows Phase 4, as T056 needs (002).
  - The clean checkout is one description everywhere: a fresh clone of the pushed branch into a new empty folder outside the working repository, with `$BRANCH` and `$SRC` in quickstart C-08, C-13, C-26, the Docker checkout and tasks (003). The 003 entries under "Decided in the run" match the final spec and plan (no `.gitattributes`, `CMD ["ruby", "bin/run"]`).
  - The entries under "Decided in the run" in this report are brought in line with the final plans for 001, 002 and 003.
- **Before pushing `main`**
  - This report no longer states step 7 pushes or approval before they happen (round 1).
  - The `ProcessDailyTransfer` constructor shows `run_time: Time.now` in 002 plan P6 and in this report (round 2, DEC-30).
  - The AC-09.1 test description gives the default output path as the project root joined with `default_path` (round 2).
  - This report records step 7 review round 2 and its fixes (round 3).
  - This report records step 7 review round 3 and its fix (round 4).
  - This report records step 7 review round 4 and its fix (round 5).

### Independent review after Part 1

After Part 1 was ready for review, an independent Claude Opus 5.5 agent that did not write the specs reviewed them against `design-decisions.md` and the solution design. The assistant that started the run decided how to fix each finding, and the fixes were made in the commits below.

| # | Severity | Finding | Decision | Commits |
|---|---|---|---|---|
| 1 | Medium | 002 FR-029, the edge cases, plan P10, research R3, the command-line contract, tasks T011, T027 and T061, and 003's spec, quickstart and tasks T015 and T021 showed a file below the parent folder with one leading `../`. [DEC-26](../design-analysis/design-decisions.md#dec-26) shows the path relative to the folder the command was run from, or in full if the file is outside it; page 02 AC-08.4 contradicted DEC-26 | Follow DEC-26: page 02 AC-08.4 shows the full path when run from `docs`, and every spec, plan, research note, contract and task uses "relative when in or below the current folder, otherwise in full". The tests keep exact expected text: the run from a subfolder expects the full path built from the temporary folder (`run_scenario` returns `temp_folder`) | `197caa9` Run change: AC-08.4 shows the output path in full when run from docs (DEC-26); `14d5818` Fix independent review finding 1: show a path outside the run folder in full (DEC-26) |
| 2 | Low | [DEC-32](../design-analysis/design-decisions.md#dec-32) named `CSV.foreach`, while 002 plan P29, research R1 and task T015 read with `CSV.open` and `csv.shift`, which [DEC-07](../design-analysis/design-decisions.md#dec-07)'s physical line numbers need | Reword DEC-32 to say the transfers file is read one row at a time with Ruby's CSV library (`CSV.open`, one row per `shift`), so physical line numbers are kept; the specs (FR-006, P29, R1, T015) cite that wording | `5ce0b1a` Run change: DEC-32 names CSV.open with one row per shift; `08c69d7` Fix independent review finding 2: specs cite DEC-32's CSV.open wording |
| 3 | Low | 002 plan P2 `Row`, P3 `CsvRows` and P10 `DisplayPath` were not on page 06 or the page 10 glossary, and `DisplayPath` made `application/errors.rb` and `process_daily_transfer.rb` depend on `infrastructure/display_path` | Remove the application to infrastructure dependency: the `Runner` gives `ProcessDailyTransfer` the balances and transfers paths in their shown form and the output path in full, the application errors and `ProcessDailyTransfer` show the paths they are given, and only `infrastructure/` uses `DisplayPath`. `CsvRows`, `Row` and `DisplayPath` are added to page 06, the page 10 components glossary and the assistant's picks (52, 53) as infrastructure helpers. Every message and output stays the same | `bb2f85c` Run change: page 06 and 10 add the infrastructure helpers CsvRows, Row and DisplayPath; `0445dee` Fix independent review finding 3: no application class depends on DisplayPath |
| 4 | Low | 002 tasks T039, T070 and T077: per-row and per-value `describe` groups would nest 4 levels, beyond RuboCop `RSpec/NestedGroups`' limit of 3 in the tasks' own convention | Each such group sits directly under its FR group, named with the AC ID and the value, for example `describe 'AC-09.5 LOG_LEVEL=INFO'`; the convention line says so too | `d88621c` Fix independent review finding 4: per-row and per-value groups sit under the FR group |
| 5 | Low | Page 10 assistant's pick 53 said it kept `application/` free of any dependency on `infrastructure/`, which is false: `LoadBalances` rescues `UnreadableFile` (page 6 pick 33) and `ProcessDailyTransfer` asks `FinalBalancesCsvWriter.default_path` (page 6 pick 35) | Reword the reason to the dependency actually removed, `infrastructure/display_path`, and name picks 33 and 35 as the only application-to-infrastructure uses left. Plan P11 and FR-030 already say only that no `application/` file requires `infrastructure/display_path`, so they match and are unchanged | `eceb4ee` Run change: page 10 pick 53 reason names the dependency actually removed |

| Round | Reviewer | Defects found | Result |
|---|---|---|---|
| 1 | Claude Opus 5.5, independent | 4 (1 medium, 3 low): findings 1 to 4 | All 4 fixed in the commits above |
| 2 | Claude Opus 5.5, independent, fresh | 1 (low): finding 5 | Fixed in `eceb4ee` |
| 3 | Claude Opus 5.5, independent, fresh | 2 (2 low) | Both fixed: the page 10 pick 53 Run change `eceb4ee` is listed in "Changed in the run" and the finding 5 row names it (`43c7cf9`); tasks T023 gives each AC-09.1 argument case its own `describe` directly under its FR group (`7cfe187`) |
| 4 | Claude Opus 5.5, independent, fresh | 0 | Review passed |

Before the push, a separate Claude Opus 5.5 agent that did not write or fix any of these changes reviewed all the commits since `8099cdf`:

| Approval check | Defects found | Result |
|---|---|---|
| 1 | 1 (low): this round table had folded rounds 1 and 2 together | Fixed in `c170843` |
| 2 | 1 (low): the heading of the `/speckit-analyze` issues left after round 3 said none was changed in this run, while three are marked resolved | Fixed in `d61e749` |
| 3 | 1 (low): this approval table was missing | Fixed in `8742f51` |
| 4 | 1 (low): the table recorded this check's approval and the push before they happened | Fixed in the commit that removes that row; the final approval and the push are recorded after they happen |
| 5 | 0 | Approved at `be2c18a`; `spec-kit-specs` and `main` were then pushed to `be2c18a` |

A scripted check over `specs/`, the solution design and `design-decisions.md` then passed: no rule that shows a file below the parent folder with a leading `../`, no `CSV.foreach`, and no `application/` file, class or task that uses `infrastructure/display_path`. The same check fails on every point against the specification as it was before these commits. Two `application/` to `infrastructure/` uses remain, both set by the solution design and outside these findings: `LoadBalances` rescues `UnreadableFile` (page 6 pick 33) and `ProcessDailyTransfer` asks `FinalBalancesCsvWriter.default_path` when no output path is given (page 6 pick 35).

### Left for the developer

1. Review the specs, plans and tasks, and every item under "Decided in the run" (the assistant's picks).
2. Finding 3 of the independent review: the infrastructure helpers `CsvRows`, `Row` and `DisplayPath` on page 06 and page 10 (picks 52 and 53), and the `Runner` passing `ProcessDailyTransfer` the balances and transfers paths in their shown form and the output path in full, so no application class depends on `DisplayPath`. Also confirm whether the two remaining `application/` to `infrastructure/` uses (page 6 picks 33 and 35) are acceptable.
3. Finding 1 of the independent review: the path rule of DEC-26 as now applied everywhere, relative when the file is in or below the folder the command was run from, otherwise in full, so `../bin/run` from `docs` shows the output file's full path (page 02 AC-08.4).
4. 001 plan D1 pins Ruby 3.4.12, the latest 3.4.x when the plan was written.
5. Part 2 (implementation) is next.

Medium and low `/speckit-analyze` issues left after round 3. The three marked "Resolved" were fixed by the independent review after Part 1; the rest are not changed in this run:

- **001-domain** (2 low)
  - Low: the "Run outcome" bullets under User Story 5's scenarios 1, 2 and 4 (spec.md lines 281 to 288) start at column 0.
  - Low: the plan says three times that the seven error classes have no spec file of their own.
- **002-file-runner** (1 medium, 5 low)
  - Medium: plan P29 and research R1 read the transfers file with `CSV.open` and `csv.shift`, while DEC-32 names `CSV.foreach`. Resolved by finding 2 of the [independent review after Part 1](#independent-review-after-part-1).
  - Low: research R9 says FakeReporter records only `printed` calls, while T019 also records `file_existed`.
  - Low: tasks.md does not say how the new support helpers reach the examples.
  - Low: the nesting depth of variant scenarios is unclear against the three-level cap in the conventions. Resolved by finding 4 of the [independent review after Part 1](#independent-review-after-part-1).
  - Low: the edge-case row for an invalid balances file with an empty transfers file cites T028, which the analyzer flags as not matching that case.
  - Low: the parent-folder path rule is worded two ways (FR-029, plan P10 and the command-line contract say "exactly one leading ../"). Resolved by finding 1 of the [independent review after Part 1](#independent-review-after-part-1).
- **003-delivery** (4 low)
  - Low: quickstart.md C-43 and T059 (and T050) name different paths for the `git ls-files --eol` check.
  - Low: T059 sits in Phase 5, after T022, so the task IDs are out of sequence.
  - Low: plan "Decided in the run" item 19 uses history wording.
  - Low: research R-2 and spec item 4 say a lock file made on Windows lists only the Windows platform, which the analyzer says conflicts with the Gemfile.lock platform decision.

## Part 2: Implementation

Started by [P26](../prompts/prompts-implementation-phase.md#p26), from the pushed specs branch `spec-kit-specs` at `13c72c2`. Part 2 runs as a multi-agent workflow with the models in rule 6 of the brief. Every review is done by an independent Claude Opus 5.5 agent that did not write or fix what it reviews, and the reviewer model is recorded for each round.

The specs are implemented one after another, each in its own worktree in `C:\Dev\`, branched from the previous spec's implementation: `001-domain-impl` from `spec-kit-specs`, `002-file-runner-impl` from `001-domain-impl`, and `003-delivery-impl` from `002-file-runner-impl`.

**Status: In progress.**

### Status

| Step | State |
|---|---|
| 1. Start | Done: this section, [P26](../prompts/prompts-implementation-phase.md#p26) and the "Current stage" in `CLAUDE.md` |
| 2. Implement 001-domain | Done: 2 review rounds. Round 1 found 1 low defect (fixed); the last round, round 2, found 0 defects. Branch `001-domain-impl` pushed with its small commits kept |
| 2. Implement 002-file-runner | Not started |
| 2. Implement 003-delivery | Not started |
| 3. Whole-system checks | Not started |
| 4. Merge and push | Not started |
| 5. Stop | Not started |

### Environment

- Ruby 3.4.12 (RubyInstaller, `x64-mingw-ucrt`) with the MSYS2 development toolchain, which Bundler needs on Windows to build the native extensions of `bigdecimal`, `json` and `prism`. Both were installed for this run.
- Docker 29.6.1 with Linux containers.

### Check results

#### 001-domain

Final checks, run on the branch after the last review round. All four criteria pass.

| Check | Result |
|---|---|
| RSpec (`bundle exec rspec`) | 160 examples, 0 failures. Randomized with seed 49805 |
| Coverage (SimpleCov) | Line coverage: 143 / 143 (100.00%) |
| RuboCop (`bundle exec rubocop`) | 0 offenses (18 files inspected, no offenses detected) |
| Unchecked tasks in `specs/001-domain/tasks.md` | 0 |
| Git status | Clean. The coverage report that the RSpec run regenerates is generated output and is ignored by git |

Review rounds. Every round is by an independent Claude Opus 5.5 agent.

| Round | Reviewer | Defects found | Result |
|---|---|---|---|
| 1 | Claude Opus 5.5 (independent, fresh) | 1 (low) | Fixed (F1) |
| 2 | Claude Opus 5.5 (independent, fresh) | 0 | Converged |

#### 002-file-runner

Design review of the run's cost (Phase 9, T079 to T081), against the [time and space table](../solution-design/09-considerations.md#time-and-space). `m` is the number of accounts and `n` the number of transfer rows. Result: 0 steps whose cost grows faster than the rows in the two files.

| Check | Result |
|---|---|
| T079 Load the balances | `LoadBalances` does one `include?` per row with a valid account number and at most one `add` per row (only for a row with no problem). Line numbers of loaded accounts sit in a `Hash`, so a duplicate's first line is one lookup. O(m) time and space |
| T079 Apply one transfer | `TransferService#apply` does two `find`s (hash lookups in `AccountRepository`), then `withdraw` and `deposit`. O(1) per transfer |
| T079 Total check and writer | `ProcessDailyTransfer#total` sums `AccountRepository#all` once before and once after the transfers; `FinalBalancesCsvWriter#write` writes one line per account. Each visits each account once. `all` returns a new array of the `m` accounts each time, so each pass holds O(m) references for a moment, still within O(m + n) |
| T079 No nested loops | No loop over rows or accounts runs inside another. `DayResult`'s counts and `ReportPrinter` each pass over the results once; the rejected counts order a tally by the fixed list of reason codes |
| T079 Whole run | O(m + n) time and space |
| T080 Reading the files | `CsvRows` reads with `CSV.open` and `shift`, holding one row (`csv.line`) at a time; nothing in `lib/` reads a whole file into a string (no `File.read`, `readlines` or `IO.read`) |
| T080 What grows with the transfers | Only the `results` array: one `TransferResult` per row, kept for the report (DEC-26) |
| T080 Limits | No fixed limit on accounts or rows: no maximum, count check or size constant in `lib/` |
| T081 Nothing kept between runs | No class variable, no global variable (`$stdout`, `$stderr` and `ENV` are only read as defaults for the `Runner` and `ReportPrinter` streams), no class-level state; every constant is frozen. `Runner#run` builds a new `AccountRepository` and new parts for each run |
| T081 Files written | Only the output file, by `FinalBalancesCsvWriter` (which creates its folder if missing). Logs go to the error stream |
| T081 AC-09.7 | The two runs on the sample files in `spec/infrastructure/runner_spec.rb` give the same report apart from the Output file line and the same output file contents: 9 examples, 0 failures |
| RSpec (`bundle exec rspec`) | 721 examples, 0 failures. Randomized with seed 23498 |
| RuboCop (`bundle exec rubocop`) | 52 files inspected, no offenses detected |

### Decided in the run

- **001-domain**
  - Kept `SimpleCov.start { add_filter '/spec/' }` exactly as T008 and plan D20 specify. simplecov 1.3.2 prints a deprecation notice suggesting `SimpleCov.skip '/spec/'` (same behaviour); the notice does not fail the run. For developer review: switching to `skip` would mean changing T008, D20 and research R11.
  - Saved the new text files with CRLF line endings to match `core.autocrlf=true` and RuboCop's default `Layout/EndOfLine` (native) on Windows. `Gemfile.lock` stays as Bundler wrote it.
  - Did not add more `.gitignore` patterns, because T006 lists exactly `coverage/` and `output/`.
  - `Money` keeps its BigDecimal behind a protected reader `value`, so `<=>`, `==` and later `+`/`-` can read another Money's value while the BigDecimal stays hidden from callers (in line with plan D5). Recorded here only, not in the plan.
  - `AccountNumber#==` and `Money#==` return false for an object of another class. They do not raise.
  - Errors with one message form are raised as `raise ErrorClass, arg` (RuboCop's default `Style/RaiseArgs`), which builds them with `new(arg)` as D21 says.
  - The `AccountNumber` equality example builds two separate objects from the same text, because RSpec/IdenticalEqualityAssertion flags the same expression written on both sides.
  - New files from the Write tool were converted to CRLF with unix2dos so they match the checkout. Git still stores the files with LF.
  - The repeated add and subtract examples in `spec/domain/money_spec.rb` use two small helpers (`add_times`, `subtract_times`, via `Array#reduce`) inside the arithmetic describe, so each example stays one expectation.
  - The `include?` example with "a different AccountNumber object built from the same text" uses a fresh `account_number('1111234522226789')` builder call, not `AccountNumber.new`, so the spec file requires only `domain/account_repository`, as the spec convention asks.
  - The `repository_with` builder uses `AccountRepository.new.tap` with `add` for each account, so a duplicate passed to the builder raises `DuplicateAccount` just as `add` does.
  - `AccountRepository#add` raises with `raise DuplicateAccount, account.number`, the same style `Account` uses for `NegativeBalance`.
  - The T035 examples go in a context "with a number it does not hold" inside the existing describe `#find`. They build the three-account repository from the spec's existing `three_numbers` let, because the `three_accounts` helper only arrives in Phase 8 (T039).
  - `UnknownAccount` is raised as `raise UnknownAccount, account_number` inside the fetch block, which calls `UnknownAccount.new(account_number)`. This matches how `DuplicateAccount` is raised in `add`.
  - `TransferResult.rejected` raises `ArgumentError` with the message "unknown reason code :<reason>" (the tasks fix only the class, D10). The spec checks the class only.
  - `TransferResult.new` is private (`private_class_method`), so `applied` and `rejected` are the only two ways to build a result (D9: an applied result cannot carry a reason or hint). `applied?` is `reason.nil?`.
  - `TransferService` requires `account_repository` and `transfer` with `require_relative`, so the error classes the service raises are loaded with it (D13).
  - The "refused while building the transfer" and "one refusal of each kind" cases in `transfer_service_spec` are table-driven (error class to transfer fields), each refusal rescued by its own class with `attempt`, to stay within RSpec/ExampleLength.
  - The "values kept as written" `TransferResult` example is one example per amount (`''` and `'10.'`), each with reason `:invalid_amount`.
  - T048 / FR-029: `TransferResult`'s `line_number` reader does not break "the domain knows no line numbers". `data-model.md` says `TransferResult` holds a line number, and T043 sets the field. The domain only stores the number it is given and never works one out or puts it in a message.
  - T047: the 10 message table rows count "empty", "more than 2 decimal places" and "not a valid amount" as one row each, covering both the balance and amount wording. Every row's text is found in a `raise_error` expectation in `spec/domain`.

### Changed in the run

None for 001-domain.

### Fixed in review

- **001-domain**
  - Round 1, F1 (low): DEC-09 is now named in the examples for `-0` and `-0.00` equality, the `-0` and `0` hash example, and the example that a computed Money is negative only below 0 (5.01 from 5.00). No expectation changed. Commit `9084dd4`.
  - Round 2 found no defects.
  - Not a defect: none.

### Left for the developer

To be filled in at the end of Part 2.
