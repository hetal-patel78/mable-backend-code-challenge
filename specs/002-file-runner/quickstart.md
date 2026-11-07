# Quickstart: validate the file reading, the day's run and the runner

How to check that `002-file-runner` is done. It proves every scenario in the [spec](spec.md) through the test suite and by running the command by hand. The domain is `001`'s and is already checked by its [quickstart](../001-domain/quickstart.md).

## Prerequisites

- Ruby 3.4.12, as in `.ruby-version` (`001` research R1), and Bundler.
- A clean checkout of the `002-file-runner` branch, built on `001-domain`, and `bundle install` done.
- Run every command from the project root unless a step says otherwise.

## Steps and expected outcomes

| # | Command | Expected outcome | Proves |
|---|---|---|---|
| 1 | `bundle exec rspec` | Every example passes; documentation format lists each example as a sentence, grouped by class and, in `Runner`, by FR; ends with `Randomized with seed <n>`; `coverage/index.html` is written; no minimum fails the run | US8 scenarios 1 to 7; FR-042 to FR-048; SC-002 to SC-006 |
| 2 | `bundle exec rspec` twice more | Passes each time with a different seed | SC-005 |
| 3 | `bundle exec rspec spec/acceptance` | Exactly 5 spec files, each describing one end-to-end run, all passing | FR-044; SC-005 |
| 4 | `bundle exec rubocop` | `no offenses detected` | SC-008; NFR-05 (owned by `001`) |
| 5 | `bin/run` (on Windows `ruby bin/run`) | Standard output exactly AC-08.1's report, with today's date and time in the `Output file:` line; standard error empty; exit status 0 (`echo $?`); a new file in `output/` holding the five AC-08.1 balances, LF line endings | US1; AC-08.1; SC-001 |
| 6 | `cd docs && ../bin/run; cd ..` | The last report line is `Output file: ../output/final_balances_<date>_<time>.csv` | AC-08.4 |
| 7 | `LOG_LEVEL=info bin/run` | Standard error holds `Run started`, four `Line N applied` lines and `Run ended: processed 4, applied 4, rejected 0`, each in the `I, [...]  INFO -- : ` format with masked numbers | AC-09.5, AC-09.6 |
| 8 | `bin/run data/mable_account_balances.csv` | Standard error exactly the two usage lines; standard output empty; exit status 1 | AC-09.2 |
| 9 | `bin/run missing1.csv missing2.csv` | Two `Error: file not found:` lines, then one `Run stopped: start checks failed (file not found)` log line; exit status 1 | AC-09.3 |
| 10 | `bin/run data/mable_account_balances.csv data/mable_transactions.csv output/day1.csv`, then the same command again | The first completes (exit 0) and writes `output/day1.csv`; the second stops with `Error: output file already exists: output/day1.csv. Delete it or give another output path.` and exit 1, and the file is unchanged | AC-08.3, AC-09.3; DEC-25 |
| 11 | `git status --short` | Nothing under `output/` or `coverage/` is listed | DEC-27, DEC-36 |
| 12 | `git diff --no-index docs/challenge/mable_account_balances.csv data/mable_account_balances.csv` and the same for the transfers file and for `spec/fixtures/sample/` | No difference | FR-038 |
| 13 | `git ls-files -s bin/run` | Mode `100755` | FR-037 |
| 14 | `git ls-files lib spec bin data` | `lib/application/` and `lib/infrastructure/` hold the files in the [plan](plan.md#source-code-repository-root); one spec file per class; exactly 5 files in `spec/acceptance/` | FR-042, FR-044 |

Delete the files written in `output/` by steps 5, 6, 7 and 10 afterwards; `output/` is ignored by Git.

## Design review

Checked by reading, not by a test (NFR-03, constitution I and II):

- The [time and space table](../../docs/solution-design/09-considerations.md#time-and-space) holds: `LoadBalances` does one `include?` and at most one `add` per row; `ProcessDailyTransfer` does two `find`s per transfer through `TransferService`; totals and the writer visit each account once; no loop inside a loop over rows or accounts (SC-007, FR-039).
- `CsvRows` holds one row at a time; nothing reads a whole file into a string (FR-040).
- Nothing is kept after a run: no class variable, no file other than the output file (FR-041).
- Every rule in [data-model.md, one home per rule](data-model.md#one-home-per-rule) is found in exactly one class.
- No class under `lib/application/` writes to standard output or standard error, reads `ENV` or calls `Time.now` other than as `ProcessDailyTransfer`'s default argument; only `ReportPrinter` and `Runner` write to a stream (FR-023, FR-036).

## Where the details are

- Members and exact messages: [contracts/components-api.md](contracts/components-api.md).
- The command's arguments, streams and exit status: [contracts/command-line.md](contracts/command-line.md).
- Fields and rules: [data-model.md](data-model.md).
- Every test, with its scenario and DEC ID: `tasks.md`.
