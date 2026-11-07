# Spec Kit run report

The record of the Spec Kit run described in the [Spec Kit brief](spec-kit-brief.md). It is updated after every step.

Back to [project instructions](../../CLAUDE.md).

## Part 1: Specification

Started by [P24](../prompts/prompts-spec-creation-phase.md#p24), from the branch `spec-kit-setup`. Every review in Part 1 (each per-spec review round, the cross-check and the review before `main` is pushed) is done by an independent Claude Opus 5.5 agent that did not write or fix what it reviews ([P25](../prompts/prompts-spec-creation-phase.md#p25)); the reviewer model is recorded for each round.

### Status

| Step | State |
|---|---|
| 1. Start | Done |
| 2. Constitution | Done |
| 3. Specs | Done |
| 4. Clarify, plan and tasks | Incomplete: 001 2 rounds, 002 1 round, 003 12 rounds; no spec reached 0 defects; no branch pushed |
| 5. Cross-check | Not started |
| 6. Scripted checks | Not started |
| 7. Merge and push | Not started |
| 8. Stop | Not started |

### Check results

Step 4 reviews. Every round is by an independent Claude Opus 5.5 agent that did not write or fix the spec.

| Spec | Round | Reviewer | Defects found | Result |
|---|---|---|---|---|
| 001-domain | 1 | Claude Opus 5.5 (independent) | 7 (2 medium, 5 low) | All 7 fixed |
| 001-domain | 2 | Claude Opus 5.5 (independent) | 3 (1 high, 1 medium, 1 low) | 2 fixed; R2-01 (high) open |
| 002-file-runner | 1 | Claude Opus 5.5 (independent) | 7 (1 high, 1 medium, 5 low) | 6 fixed; R1-01 partly fixed, the DEC-36 conflict is open |
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
| 003-delivery | 12 | Claude Opus 5.5 (independent) | 2 (1 medium, 1 low) | Fixed; not re-reviewed |

No spec reached a round with 0 defects, and no spec branch was pushed.

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
  - Money equality and comparison use the amount only, so -0 equals 0. The written minus sign only decides whether a value counts as negative. A Money made by adding or taking away is negative only when its amount is below 0.
  - `Account#withdraw` and `#deposit` do not check that the amount is above $0. That rule stays in `Transfer`, which `TransferService` relies on.
  - Ruby 3.4.12 goes in `.ruby-version`, the highest 3.4.x release on 2026-11-08.
  - No namespace module: every class and error is a top-level constant with its page 6 name. The seven errors are in `lib/domain/errors.rb`, each a direct `StandardError` subclass with no spec file of its own, and each is tested where it is raised.
  - `Money.amount(text)` and `Money.balance(text)` set the word "amount" or "balance" in the messages. Money members are `text`, `to_s`, `+`, `-`, `<=>` (with `Comparable`), `==`, `eql?`, `hash`, `negative?`, `positive?`, and `Money.new(value, text = nil)`.
  - `Account.new(number, balance)` and `Account.check_opening_balance(balance)`, which raises `NegativeBalance`. `Transfer.new(from:, to:, amount:)` takes keywords.
  - `TransferResult.applied(line_number:, fields:)` and `.rejected(line_number:, fields:, reason:, header_hint: nil)`. `REASON_CODES` is a frozen list of symbols in DEC-19 order, and an unknown reason raises `ArgumentError`. 002 supplies the header hint text. `TransferService.new(repository)` and `#apply(transfer)` return nil.
  - Files load their own dependencies with `require_relative`. The Gemfile lists the runtime gems at top level and the four tools in group `:development, :test`, with no version constraints and no ruby line. Gemfile.lock pins the platforms x86_64-linux and x64-mingw-ucrt.
  - `.rubocop.yml` holds only `plugins: [rubocop-rspec]`. Every file has a frozen_string_literal comment and each class a one-line comment, because RuboCop's defaults require both.
  - Specs follow rubocop-rspec defaults, with one expectation per example. A helper `attempt(error_class)` rescues only the named error. "Deposit is never called" is proven by the receiving balance staying unchanged, not by a spy.
  - `AccountNumber`, `Money`, `Transfer` and `TransferResult` freeze when built. SimpleCov starts at the top of `spec_helper`, filtering `/spec/`.
  - An error with one message form builds its message from its values, for example `DuplicateAccount.new(account_number)`. `InvalidAmount` takes the full message because it has four forms.
  - Tasks follow code dependency (US4, US6, US2, US5, US3, US1), not priority. Each error and test builder is added in the phase whose test first needs it. The service-level views of AC-04.x, AC-05.x and US6 scenario 4 are tested in the US1 phase, where `TransferService` is built.
  - DEC-09's own examples (100, 100.5, 100.50 valid; 100., +100, $100 invalid) are tested alongside the table rows.
- **002-file-runner**
  - Runner scenarios run in the same process, in a temporary folder. The test writes the CSV files there, so they are not fixture files. This keeps the end-to-end runs at 5.
  - The five end-to-end runs are AC-08.1, AC-08.2, AC-02.3, AC-01.4 and AC-09.2 (one argument).
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
  - `LoadBalances.new(reader, repository).call(path)`. `ProcessDailyTransfer.new(run_time:, **parts)` takes exactly the six named parts, and `call(balances_path, transfers_path, output_path = nil)` returns the DayResult.
  - DayResult is a Data value with counts, `rejected_counts` in DEC-19 order, `all_rejected?`, and `ALL_REJECTED_WARNING`. The report and the run-end log count the same results.
  - Each run-stopping error builds its own message and `stop_reason`. The reason from the system is the message up to Ruby's " @ " call details.
  - `DisplayPath.of(path, folder)` shows a path relative to the current folder when the file is in it, below it, or below its parent (one `../` step), and in full otherwise. The Runner converts each path once, and later parts use that text.
  - `Runner.new(stdout:, stderr:, env:).run(arguments)` returns 0 or 1. `ReportPrinter.new(output:, current_folder:).print(day_result)`. The logger is at info when `LOG_LEVEL` is `casecmp?('info')`, otherwise warn.
  - The writer creates missing folders with `mkdir_p`, opens the file with `WRONLY|CREAT|EXCL|BINARY`, writes LF only, and deletes the file only if it created it before raising `OutputNotWritable`.
  - An applied amount is shown and logged as `Money.amount(text).to_s`. A rejected value is shown as written, and an empty value as `""`.
  - Page 2 scenarios are in `spec/infrastructure/runner_spec.rb`, grouped by FR. The five end-to-end specs are `RSpec.describe Runner` in `spec/acceptance/runner_<case>_spec.rb`.
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
  - `.gitattributes` gets one line, `bin/run text eol=lf`. With `core.autocrlf=true` on Windows, `bin/run` would otherwise get CRLF line endings, and the Docker image would fail on its shebang line. `* text=auto eol=lf` was rejected as wider than needed.
  - The Docker default command is `CMD ["bin/run"]` in exec form, not run through `bundle exec`, so the exit status is the program's. A command after the image name replaces it.
  - The container runs as the image's default user, root, with no `--user`. The README says in one line that the output file may belong to root on a Linux host.
  - The README sections follow the order of DEC-37: build, test and run (with Ruby, on Windows and with Docker); input files; log level and exit status; assumptions; design; test coverage; storage, production items and known limitations; how this was built; repository layout; the challenge.
  - `.ruby-version` holds the bare version number, with no `ruby-` prefix. The Dockerfile's first line is `FROM ruby:` followed by the same text, and check C-04 compares them.
  - `Gemfile.lock` lists the platforms ruby, x64-mingw-ucrt, x86_64-linux, aarch64-linux, x86_64-darwin and arm64-darwin, added with `bundle lock --add-platform`. No gem versions change.
  - `.github/workflows/ci.yml` is named CI and runs on push with no branch filter. It has one job, `checks`, on ubuntu-latest, with five steps: checkout, ruby/setup-ruby (which reads `.ruby-version`), `bundle install` with `BUNDLE_FROZEN=true`, `bundle exec rspec`, and `bundle exec rubocop`. `actions/checkout@v5` and `ruby/setup-ruby@v1` are pinned to major versions. The bundler cache is not used.
  - Frozen installs use `BUNDLE_FROZEN=true` in CI, Docker and the checks, not `--frozen` or deployment mode. The README tells a reviewer to run plain `bundle install`.
  - The Dockerfile has exactly six instructions: `FROM ruby:<version>`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN bundle install`, and `CMD ["bin/run"]`. There is no `USER` line. If the default `ruby:<version>` image lacks `/usr/share/zoneinfo`, the `-bookworm` variant is used, since installing tzdata would add a package FR-024 does not allow.
  - The README's Docker commands are: build with `docker build -t mable-transfers .`; run with `-v "$(pwd)/output:/app/output"` in a POSIX shell, or `-v "${PWD}/output:/app/output"` in PowerShell; both runs use `--rm` and `-e TZ=Australia/Sydney`. The test run is `docker run --rm mable-transfers bundle exec rspec`. There is no `--user` and no `-it`.
  - The coverage figure is SimpleCov's printed `Line Coverage` line from a full run on a clean checkout of the final code. After the push it is compared with the CI log of the latest `main` commit.
  - The README title and the challenge link keep the challenge's own name. FR-014's "no company named" is read as the company whose balances are processed.
  - The checks are commands in `quickstart.md`, with results in the run report. No script or folder is added for them. Line endings are checked with `git ls-files --eol`, and copies of the challenge files by Git blob ID, so both give the same result on a Windows checkout.
  - If `bin/run` is not stored as mode 100755, the fix is `git update-index --chmod=+x bin/run`, with no content change.
  - The Windows checks clone with `git clone -c core.autocrlf=true`, so the data files get CRLF line endings, and they use PowerShell's `$LASTEXITCODE`.
  - During development, the clean checkout is a fresh clone of the implementation branch from the local repository. The final repeat runs on a fresh clone of `origin/main` after the push. If no Linux or macOS machine is available, US1's checks run in one official `ruby:<version>` container with the clean checkout mounted, and the run report says so.
  - The CI run is checked on the pushed implementation branch and again on `main`. If the code changes after the coverage figure was taken, the figure is updated and C-33 is repeated.

### Changed in the run

None.

### Fixed in review

- **001-domain**
  - Money equality, `eql?` and `hash` now agree across the plan, research, data model and tasks.
  - Acceptance scenarios that lacked a standard output, error or exit statement now have one (US1, US3, US5 and US6).
  - Money comparison tests now follow the test-first rule (constitution IV).
  - AC-03.2 and T040 now state the domain outcome, and the domain API table has its blank line restored.
  - `lib/domain/errors.rb` now has a task.
  - Task references to AC-05.3 are corrected.
  - Not fixed: R2-01 (RuboCop `Metrics/BlockLength` against spec files) needs the developer's change to DEC-36.
- **002-file-runner**
  - The false RuboCop limit claim in research R8 is removed. The conflict with DEC-36 is still open.
  - AC-08.3, AC-09.7 and US5 now state the standard output, error and exit code, and T061 matches.
  - The DisplayPath rule is the same in FR-029, the edge cases, plan P10, the data model and the command-line contract.
  - T070's line count, the US6 build-order sentence and the checklist's item count are corrected.
  - The test helper signatures in research R9 match tasks T019 and T021.
- **003-delivery**
  - Windows check commands: byte-for-byte stream comparison, `$env:CHECKS`, `$REPO`, `$LASTEXITCODE`, clone paths and output redirection.
  - Docker checks: the README-command check (C-41), C-29 run as written, the Dockerfile first-line check, the C-21 redirect, the fresh-checkout folders, and the expected output folder.
  - The container fallback for Phase 4, used when no Linux or macOS machine is available, is written out in full.
  - Acceptance scenarios now state the standard output, error and exit code (US1 to US5), and the Docker build log is not compared exactly.
  - Requirements and tasks: FR-019 has a task, FR-014's wording is the same in the spec, plan, contracts and data model, and the FR-025(c) and SC-001 wording and the Key Entities list match.
  - Check counts in the plan match `quickstart.md`, and the commands for C-01, C-28, C-40 and C-42 are corrected.
  - Tasks: phase checkpoints, the Spec Kit task ID format, the Phase 9 order, the T006 vs FR-030 mismatch, and the coverage update wording in T050.
  - Repository files: the pushed `main` must be tracked, and the contract's "nothing more" list matches the spec.

### Left for the developer

None yet.
