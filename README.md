# Mable Back End Code Challenge

A command-line program that loads one company's starting account balances from a CSV file and applies one day's transfers from a second CSV file, never letting an account balance go below $0. It prints a report of the day and writes the closing balances to a new CSV file.

## Prerequisites

You need Git to clone the repository, and either Ruby or Docker.

| You need | Version | Check with |
|---|---|---|
| Git | any recent version | `git --version` |
| Ruby | 3.4, the version in [`.ruby-version`](.ruby-version) (3.4.12) | `ruby -v` |
| Bundler | the one that comes with Ruby 3.4 | `bundle -v` |
| Docker, instead of Ruby | any recent version | `docker --version` |

Installing Ruby 3.4. The [ruby-lang.org installation page](https://www.ruby-lang.org/en/documentation/installation/) lists the options for each system.

- **macOS and Linux:** use a version manager such as rbenv, chruby or asdf to install and switch to the version in `.ruby-version`. The Ruby that comes with macOS, or with a Linux package manager, is often older than 3.4.
- **Windows:** use [RubyInstaller](https://rubyinstaller.org/), and pick a **Ruby+Devkit 3.4.x (x64)** download. At the end of the install, let it run `ridk install` and choose option 3, the MSYS2 and MINGW development tool chain. Some gems in `Gemfile.lock`, such as `bigdecimal`, build native extensions during `bundle install` and need it.
- If `bundle -v` finds no Bundler, install it with `gem install bundler`.

Without Ruby 3.4, use Docker instead: see [With Docker](#with-docker). If something goes wrong, see [Troubleshooting](#troubleshooting).

## Build, test and run

### With Ruby 3.4

You need Ruby at the version in [`.ruby-version`](.ruby-version) and Bundler (see [Prerequisites](#prerequisites)). From the project root:

```
bundle install
bin/run
```

Run the tests with `bundle exec rspec` and the style checker with `bundle exec rubocop`.

The program takes no arguments, 2 arguments or 3 arguments:

| Command | Balances | Transfers | Output |
|---|---|---|---|
| `bin/run` | `data/mable_account_balances.csv` | `data/mable_transactions.csv` | default name in `output/` |
| `bin/run b.csv t.csv` | `b.csv` | `t.csv` | default name in `output/` |
| `bin/run b.csv t.csv out/day1.csv` | `b.csv` | `t.csv` | `out/day1.csv` |

- Typed paths are relative to the current folder. The default paths are relative to the project root, so `bin/run` with no arguments works from any folder.
- The default output file is `output/final_balances_YYYY-MM-DD_HHMMSS.csv`, named from the local date and time the run started. A typed output file is used as given, and missing folders are created.
- An existing output file is never overwritten: the run stops instead.

With 1 argument, or with 4 or more (including `bin/run -h` and `bin/run --help`), the program prints this usage message on standard error and exits with status 1:

```
Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
With no arguments, runs the sample files in data/.
```

The sample run, `bin/run` with no arguments, prints this report:

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

A real run shows its own date and time in the last line.

### On Windows

Run the program as `ruby bin/run`, with the same arguments. Install and test as above. In PowerShell the exit status is in `$LASTEXITCODE`.

### With Docker

Docker is the alternative for a reviewer without Ruby 3.4. From the project root:

| Purpose | Command |
|---|---|
| Build the image | `docker build -t mable-transfers .` |
| Run the sample files, POSIX shell | `docker run --rm -e TZ=Australia/Sydney -v "$(pwd)/output:/app/output" mable-transfers` |
| Run the sample files, PowerShell | `docker run --rm -e TZ=Australia/Sydney -v "${PWD}/output:/app/output" mable-transfers` |
| Run the tests | `docker run --rm mable-transfers bundle exec rspec` |

- The container uses UTC for the output file name unless `TZ` is set, so set `TZ` to your own time zone.
- The mount keeps the output CSV on your machine, in `output/`.
- Your own files must be mounted into the container the same way as `output`, and their paths given as seen inside it.
- On a Linux host the output file may belong to root, because the container runs as the image's default user.

## Input files

- Both files are CSV with no header row.
- The balances file has one account per line: `account number,balance`.
- The transfers file has one transfer per line: `from account number,to account number,amount`.
- A header row is a bad row. In the balances file it makes the file invalid and stops the run. In the transfers file that row is rejected and the run continues.

## Log level and exit status

- `LOG_LEVEL` is `warn` (the default) or `info`, in any letter case. Any other value falls back to `warn`.
- Log lines go to standard error, with account numbers masked as `************6789`. The report alone goes to standard output.
- Exit status 0: the run completed, even if some or all transfers were rejected.
- Exit status 1: the run stopped, for one of these reasons: wrong arguments, a missing or unreadable input file, an invalid balances file, an empty transfers file, a file that cannot be read past a line, a changed total, an output file that already exists, or an output file that cannot be written.

## Troubleshooting

**`ruby` or `bundle` "is not recognized" right after installing Ruby (Windows).** The terminal, or the editor that started it, was opened before the installer added Ruby to `PATH`. Open a new terminal. If the editor (for example VS Code) keeps background processes running, quit it fully, or sign out of Windows and back in. Or refresh `PATH` in the current PowerShell window:

```
$env:Path = [Environment]::GetEnvironmentVariable('Path','User') + ';' + [Environment]::GetEnvironmentVariable('Path','Machine')
```

**`bin/run` opens a "Select an app to open this file" dialog (Windows).** Windows ignores the `#!/usr/bin/env ruby` first line. Run `ruby bin/run` instead, with the same arguments.

**`/usr/bin/env: 'ruby\r': No such file or directory` from `bin/run` (Git Bash or WSL on a Windows checkout).** Git on Windows usually checks files out with CRLF line endings, and a CRLF first line cannot be started directly. Run `ruby bin/run` instead. The Docker image already runs `ruby bin/run` and strips the carriage returns from `bin/run` when it is built, so a Windows checkout builds and runs the same as any other.

**`bundle install` fails to build a gem's native extension (Windows).** The MSYS2 development tool chain is missing. Run `ridk install`, choose option 3, then run `bundle install` again.

**RuboCop reports `Carriage return character missing` (Windows).** RuboCop's default `Layout/EndOfLine` setting expects CRLF line endings on Windows. A checkout made with Git's `core.autocrlf` set to `false` or `input` keeps the repository's LF endings, so every file is reported. Clone again with `git clone -c core.autocrlf=true ...`, the Git for Windows default.

**The output file name from Docker shows the wrong time.** The container uses UTC unless `TZ` is set. Pass your own time zone, for example `-e TZ=Australia/Sydney`, as in [With Docker](#with-docker).

**The run stops because the output file already exists.** An output file is never overwritten. Give a new output path, or move the old file. With the default name, this happens only when two runs start in the same second; run again.

## Assumptions

| Assumption | Reason |
|---|---|
| The balances file lists every account of the company. | Transfers to or from any other account are rejected as unknown ([DEC-17](docs/design-analysis/design-decisions.md#dec-17)). |
| The order of rows in the transfers file is the order the company intends. | Transfers are applied in file order ([DEC-15](docs/design-analysis/design-decisions.md#dec-15)). |
| Money is in dollars and cents, with no other currency. | The challenge uses $ only, and amounts have at most 2 decimal places ([DEC-09](docs/design-analysis/design-decisions.md#dec-09)). |
| One transfers file holds one day's transfers. | The challenge accepts "a day's transfers in a CSV file" ([DEC-02](docs/design-analysis/design-decisions.md#dec-02)). |
| An account number may start with 0. | The challenge says only "16 digit number", so leading zeros are kept ([DEC-08](docs/design-analysis/design-decisions.md#dec-08)). |
| The "test files" in the rubric are the two sample CSV files. | Their exact expected results are checked ([DEC-35](docs/design-analysis/design-decisions.md#dec-35)); reviewers' own files are covered by the rejection rules. |
| The program is run from the command line by one person. | The rubric asks that it "runs and provides feedback"; no web service or concurrent use is described ([DEC-22](docs/design-analysis/design-decisions.md#dec-22)). |
| The input files are UTF-8 text. | CSV files from spreadsheets and editors are UTF-8 by default; anything else is unreadable ([DEC-04](docs/design-analysis/design-decisions.md#dec-04)). |
| A day's transfers fit in memory. | One company's daily transfers are small ([DEC-32](docs/design-analysis/design-decisions.md#dec-32)). |
| The reviewer has Ruby 3.4, or Docker. | Docker is the fallback for anyone without Ruby 3.4 ([DEC-36](docs/design-analysis/design-decisions.md#dec-36)). |

## Design

- Light domain-driven design: the rules live inside the models (`AccountNumber`, `Money`, `Transfer`, `Account`, `AccountRepository`), with plain names and no ceremony.
- The code is in three folders:
  - `lib/domain` holds the models and their rules: what a valid account number and amount are, and that a balance never goes below $0.
  - `lib/application` holds the use cases: loading the balances (`LoadBalances`) and running the day (`ProcessDailyTransfer`), with the day's results and the text of its log lines (`LogMessages`, except the all-rejected warning, whose text `DayResult` owns).
  - `lib/infrastructure` holds what touches the outside world: the CSV readers and writer, the report printer and the `Runner` that `bin/run` starts.
- `AccountRepository` keeps the accounts in memory, with `add`, `include?`, `find` and `all`.
- `ProcessDailyTransfer` is given its parts as one `ProcessDailyTransfer::Parts` value, each by name (the readers, the writer, the repository, the report printer and the logger), and the run time, so the tests pass fakes.
- Every check runs before any balance changes, so each transfer is all or nothing.
- Money is a `Money` value on `BigDecimal`, never floating point, and never rounded.

The full reasoning is in [`docs/design-analysis/design-decisions.md`](docs/design-analysis/design-decisions.md) and the solution design in [`docs/solution-design/README.md`](docs/solution-design/README.md).

## Test coverage

SimpleCov's line coverage from a full `bundle exec rspec` run:

```
Line coverage: 501 / 501 (100.00%)
```

The full report is in `coverage/index.html` after a test run. No minimum figure is set.

## Storage, production and known limitations

**Persistent storage.** Every run starts from the balances file and remembers nothing. To stay safe to rerun, a version with storage would have to remember which files and transfers were already applied, so a rerun cannot apply a day twice. Remembering applied files across runs is out of scope.

**Production items.**

- Very large files would need streaming or chunking, so the results are not all held in memory.
- A database repository would need database transactions, or sagas across services, to keep each transfer all or nothing.

**Known limitations.**

- No memory of earlier runs: running the same transfers file twice on a day's output applies it twice.
- Results are held in memory, so memory grows with the number of transfer rows.
- An unreadable line in the transfers file discards the whole day, including transfers already applied in memory.
- A duplicate account whose first copy has an invalid balance is reported only after that row is fixed, on the next run.
- A balances file missing an account rejects every transfer touching it as `unknown_account`.
- Two default-path runs in the same second: the second stops, and the first file is never overwritten.
- Full account numbers appear on screen and in the output CSV; only the logs are masked.
- The Docker clock is UTC unless `TZ` is set.
- The total-check failure cannot happen with correct code, so it is tested with fakes.

## How this was built

The design and the code were made with an AI assistant, in four steps:

1. Design analysis: [`docs/design-analysis/design-decisions.md`](docs/design-analysis/design-decisions.md).
2. Solution design: [`docs/solution-design/README.md`](docs/solution-design/README.md).
3. GitHub Spec Kit specification: [`.specify/memory/constitution.md`](.specify/memory/constitution.md) and [`specs/`](specs/).
4. Test-first implementation through the Spec Kit tasks: each spec's `tasks.md` in [`specs/`](specs/).

The prompts that shaped them are in [`docs/prompts/`](docs/prompts/).

## Repository layout

| Path | Contents |
|---|---|
| `bin/run` | The command that starts the program |
| `lib/domain/` | The models and their rules |
| `lib/application/` | The use cases: loading the balances and running the day |
| `lib/infrastructure/` | The CSV readers and writer, the report printer and the runner |
| `spec/` | The RSpec tests, with their fixture files |
| `data/` | The two sample CSV files that `bin/run` uses with no arguments |
| `output/` | The output files; created by a run, not committed |
| `docs/challenge/` | The challenge brief and its two sample CSV files, unchanged |
| `docs/design-analysis/` | `design-decisions.md`, the single source of truth for behaviour and design; `handwritten/`, the developer's brainstorm pages, unchanged; `clarifications/`, the review findings and the developer's answers, unchanged |
| `docs/solution-design/` | The solution design: components, flows, alternatives and trade-offs |
| `docs/spec-kit/` | The brief for the Spec Kit run and the run report |
| `docs/prompts/` | The prompts given to the AI assistant, one log per phase |
| `specs/` | The Spec Kit specifications, one folder per spec: spec, plan, tasks and contracts |
| `.specify/` and `.claude/` | The Spec Kit set-up, including the constitution in `.specify/memory/` |
| `.github/workflows/ci.yml` | The GitHub Actions workflow that runs RSpec and RuboCop on every push |
| `Dockerfile` | The Docker image, the alternative way to run the program and the tests |
| `CLAUDE.md` | Project instructions for the AI assistant |

## The challenge

The challenge as received is [`docs/challenge/MABLE_BACK_END_CODE_TEST.md`](docs/challenge/MABLE_BACK_END_CODE_TEST.md), with its two sample files kept unchanged beside it.
