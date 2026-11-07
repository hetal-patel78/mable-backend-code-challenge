# Feature Specification: Delivery: README, CI, Docker and the submission

**Feature Branch**: `003-delivery`

**Created**: 2026-11-07

**Status**: Draft

**Input**: User description: "Spec 003-delivery, short name "delivery": the third of the three specs in the Spec Kit brief. Owns NFR-04 Language version and portability, and builds the README (with the assumptions, the coverage figure and "How this was built"), the GitHub Actions workflow, the Dockerfile, the Docker and Windows runs from a clean checkout, and the check of what the submission holds." The full input is recorded in [`docs/spec-kit/specify-inputs.md`](../../docs/spec-kit/specify-inputs.md#003-delivery).

## Sources and ownership

- **Sources, in order of precedence**: [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) (DEC-01 to DEC-38, the source of truth); the solution design pages [01](../../docs/solution-design/01-request-summary.md) (request summary and rubric), [03](../../docs/solution-design/03-non-functional-requirements.md#nfr-04) (NFR-04), [04](../../docs/solution-design/04-scope.md) (scope), [09](../../docs/solution-design/09-considerations.md) (portability and CI, README and submission, risks and known limitations) and [10](../../docs/solution-design/10-traceability-glossary-assumptions.md) (assumptions, known limitations, glossary); [page 02](../../docs/solution-design/02-functional-requirements.md) for the exact outputs this spec checks; then `CLAUDE.md` and the [constitution](../../.specify/memory/constitution.md). If this spec ever differs from them, they win.
- **Builds on**: [`001-domain`](../001-domain/spec.md) (the project skeleton: `Gemfile`, `Gemfile.lock`, `.ruby-version`, RSpec, SimpleCov, RuboCop with `rubocop-rspec`, `.gitignore`) and [`002-file-runner`](../002-file-runner/spec.md) (`Runner`, `bin/run`, `data/`, `spec/fixtures/` and the five end-to-end runs). This spec changes none of their behaviour (its only edits to `bin/run` are its Git mode, its first line `#!/usr/bin/env ruby` and, only if RuboCop then reports it, the `# frozen_string_literal: true` comment on line 2; FR-018, spec item 16), adds no class, no message and no RSpec spec, and adds no test-data file beyond those `002` creates.
- **This spec owns**: [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04) Language version and portability. It owns no other FR or NFR.
- **Built elsewhere, checked here** (brief rule 3, "Where a requirement crosses the line"): the Ruby pin in `.ruby-version`, the `Gemfile` and the committed `Gemfile.lock` are built by `001` (FR-036, FR-037 there); reading files through Ruby's CSV library with a byte-order mark ignored, and default paths found from the project root, are built and tested by `002` (FR-001, FR-031, FR-032 there; the byte-order-mark fixture test belongs to NFR-06, owned by `002`). This spec checks them as NFR-04 targets, by CI, a Docker run, a Windows run and design review, not by new RSpec specs (brief rule 4).
- **Also built here**: the README content [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) lists, the coverage figure in it ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)), and the check of what the submission holds ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)). Page 10's traceability gives these no FR or NFR of their own; page 4 lists the README and the submission in scope under [page 9](../../docs/solution-design/09-considerations.md#readme-and-submission), and the Spec Kit brief (rule 3) gives them to this spec.

### Conventions used in the scenarios

These are copied from [page 2](../../docs/solution-design/02-functional-requirements.md#how-to-read-the-acceptance-criteria), with one addition for runs made by hand:

- **Standard output** (stdout) carries the report only. **Standard error** (stderr) carries error messages and log lines. "(nothing)" means the stream stays empty.
- The **exit status** is 0 for a completed run and 1 for a stopped run ([DEC-25](../../docs/design-analysis/design-decisions.md#dec-25)). In Docker, the exit status of `docker run` is the program's exit status.
- Page 2's runs start at 2026-11-07 14:30:05 local time, from the project root, with the default log level (warn). The runs in this spec are made by hand, or by CI, at a real time: `<run time>` stands for that run's local date and time in the form `YYYY-MM-DD_HHMMSS`, and is the only part of any stream or file name that differs from page 2 (decided in the run, item 1), except that on Windows the console streams use CRLF line endings, so they are compared line by line with CRLF changed to LF, while the output CSV is compared byte for byte (decided in the run, item 15).
- Log lines use Ruby's standard log format. `<timestamp>` stands for the date and time to the microsecond and `<pid>` for the process number, which change on every run.
- The **pushed branch** is `main`, the repository's default branch and the one the submission link opens, after the merged implementation is pushed to it (DEC-38; brief Part 2 step 4). Every submission check, every clean checkout and the README's coverage figure are taken on its latest commit (Clarifications).
- A **clean checkout** is a fresh `git clone` of the pushed branch into a new, empty folder outside the working repository, with no `output/`, `coverage/` or installed gems carried over (decided in the run, item 2).
- `<image>` is the Docker image name the README uses, `mable-transfers` (decided in the run, item 5).

**The sample report.** Every sample-files run in this spec has this standard output: [AC-08.1](../../docs/solution-design/02-functional-requirements.md#fr-08-the-end-of-day-result-and-its-output) copied character for character, with `2026-11-07_143005` replaced by `<run time>`:

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
  1111234522226789  4820.50
  1111234522221234  9974.40
  2222123433331212  1550.00
  1212343433335665  1725.60
  3212343433335755  48679.50

Output file: output/final_balances_<run time>.csv
```

**The sample output file.** `output/final_balances_<run time>.csv` then holds exactly these bytes, every line ending with LF only, the last included (AC-08.1, AC-08.3):

```
1111234522226789,4820.50
1111234522221234,9974.40
2222123433331212,1550.00
1212343433335665,1725.60
3212343433335755,48679.50
```

## Clarifications

### Session 2026-11-07

- Q: Which branch do the submission checks, the clean checkout and the README's coverage figure apply to? → A: `main`, the repository's default branch, the one the submission link opens, after the merged implementation is pushed to it (DEC-38; brief Part 2 step 4).
- Q: How is `bin/run` kept with LF line endings in a Windows checkout, so a Docker image built there still starts it (Git on Windows normally checks text files out with CRLF, and a CRLF first line makes `#!/usr/bin/env ruby` fail)? → A: it is not forced, and nothing needs to force it. The repository has no `.gitattributes` file, and `bin/run` is stored with LF and mode `100755` like every other text file. In a Windows checkout made with `core.autocrlf=true`, Git gives every text file CRLF, `bin/run` included, which is the line ending RuboCop's default `Layout/EndOfLine` (style `native`) expects on Windows, so `bundle exec rubocop` reports no offence there (DEC-36). A CRLF first line cannot stop a Docker image built from such a checkout, because the image's default command runs the file through Ruby (`ruby bin/run`, next question), and Ruby ignores the line ending of the `#!` line (DEC-22, DEC-36, NFR-04). Research note: RuboCop's `Layout/EndOfLine` resolves `native` as CRLF on Windows and LF elsewhere (R-3 in research.md).
- Q: What does the Docker image run by default: `bin/run` directly, or through `bundle exec`? → A: `ruby bin/run` directly, as the Dockerfile's default command in exec form (`CMD ["ruby", "bin/run"]`), not through `bundle exec`, so a container started with no command runs the sample files, the exit status of `docker run` is the program's, a CRLF first line in a Windows checkout cannot stop it starting, and any command given after the image name (such as `bundle exec rspec` or `ruby bin/run -h`) replaces it (DEC-22, DEC-36, DEC-37).
- Q: Which user does the container run as, given that on a Linux host the mounted `output` file then belongs to that user? → A: the official image's default user (root); the README's run command adds no `--user` option, and the README says in one line that on a Linux host the output file may belong to root (DEC-36, DEC-37; `--user` with an arbitrary user id can make Bundler warn on standard error).
- Q: In what order does the README give its sections after build, test and run? → A: in DEC-37's order: build, test and run (the normal way, Windows, then Docker); the input files; `LOG_LEVEL` and exit statuses; the assumptions; the design reasoning; the test coverage; persistent storage, production items and known limitations; "How this was built"; then the repository layout and the link to the challenge (DEC-37).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A reviewer with Ruby 3.4 runs the sample files with one command (Priority: P1)

A reviewer who has Ruby 3.4 clones the repository, installs the gems with `bundle install`, and runs `bin/run` with no arguments. They get the exact sample result, with no other setup, and the same from any folder ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).

**Why this priority**: the rubric's "runs and provides feedback" and "calculates the test files accurately" depend on the program running at once on the reviewer's machine; this is the main way to run ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36): Docker is the fallback).

**Independent Test**: on a clean checkout on Linux or macOS with the Ruby version in `.ruby-version`: `bundle install`, then `bin/run`, comparing the streams, the exit status and the output file with the sample report and the sample output file.

**Acceptance Scenarios**:

1. **The gems install at the locked versions** (NFR-04; DEC-01).
   - **Given** a clean checkout and Ruby at the exact version in `.ruby-version`, **When** `bundle install` runs, **Then**:
     - Standard output: Bundler's summary line (`Bundle complete!`); not compared exactly.
     - Standard error: not compared.
     - Exit status: 0
     - And `Gemfile.lock` is unchanged (`git status` shows no change), and only the gems the lock file lists are installed.
2. **The sample files with no arguments** (NFR-04, AC-08.1; DEC-22, DEC-35).
   - **Given** that clean checkout after `bundle install`, **When** `bin/run` runs from the project root, **Then**:
     - Standard output: the sample report.
     - Standard error: (nothing)
     - Exit status: 0
     - And `output/final_balances_<run time>.csv` is the sample output file.
3. **From another folder** (NFR-04, AC-08.4; DEC-22, DEC-26).
   - **Given** the same checkout, **When** `../bin/run` runs with no arguments from the project's `docs` folder, **Then** standard output is the sample report with its last line `Output file: ../output/final_balances_<run time>.csv`, standard error is (nothing), the exit status is 0, and the file is written in the project's `output/` folder.
4. **The tests and the style checker on the reviewer's machine** (NFR-04; DEC-34, DEC-36).
   - **Given** the same checkout, **When** `bundle exec rspec` and then `bundle exec rubocop` run, **Then**, for `bundle exec rspec`:
     - Standard output: RSpec's summary with `0 failures`, a `Randomized with seed` line (random order) and SimpleCov's `Line Coverage:` line.
     - Standard error: not compared.
     - Exit status: 0
     - And SimpleCov writes `coverage/`.
   - And, for `bundle exec rubocop`:
     - Standard output: RuboCop's summary line, `no offenses detected`.
     - Standard error: not compared.
     - Exit status: 0

---

### User Story 2 - A reviewer on Windows runs `ruby bin/run` (Priority: P1)

A reviewer on Windows, where a file without an extension cannot be started directly, runs the program as `ruby bin/run`, as the README says, and gets exactly the same result as on Linux or macOS ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); page 3 pick, page 10 pick 20).

**Why this priority**: NFR-04 requires it, and a Windows reviewer is likely; CI runs on Linux only (page 10 pick 50), so this hand run is the only Windows check.

**Independent Test**: on Windows, from a clean checkout, with Ruby at the version in `.ruby-version`: `bundle install`, then `ruby bin/run` on the sample files, before submission.

**Acceptance Scenarios**:

1. **The sample files on Windows** (NFR-04, AC-08.1; DEC-22, DEC-35, DEC-37).
   - **Given** a clean checkout on Windows and `bundle install` done, **When** `ruby bin/run` runs from the project root with no arguments, **Then**:
     - Standard output: the sample report, with `/` between the folder and the file name in the last line, as on every system (decided in the run, item 3); the console stream has CRLF line endings on Windows and is compared line by line with CRLF changed to LF (decided in the run, item 15).
     - Standard error: (nothing)
     - Exit status: 0
     - And `output\final_balances_<run time>.csv` holds exactly the sample output file, byte for byte, with LF line endings, not CRLF (AC-08.3; page 10 pick 17).
2. **Wrong arguments on Windows** (NFR-04, AC-09.2; DEC-22, DEC-25).
   - **Given** the same checkout, **When** `ruby bin/run -h` runs, **Then**:
     - Standard output: (nothing)
     - Standard error, exactly (CRLF changed to LF before comparing, decided in the run, item 15):

       ```
       Usage: bin/run [BALANCES_FILE TRANSFERS_FILE [OUTPUT_FILE]]
       With no arguments, runs the sample files in data/.
       ```

     - Exit status: 1 (`$LASTEXITCODE` in PowerShell, `%ERRORLEVEL%` in Command Prompt).
3. **Windows line endings in the input** (NFR-04; DEC-04).
   - **Given** a Windows checkout, **When** `ruby bin/run` runs on the sample files, **Then**, whatever line endings the checkout gives `data/` (the files are read only through Ruby's CSV library, which accepts CRLF and a missing final newline; checked by design review, page 3):
     - Standard output: the sample report.
     - Standard error: (nothing)
     - Exit status: 0
4. **The style checker on a Windows checkout** (NFR-05; DEC-36).
   - **Given** a fresh Windows clone made with `core.autocrlf=true` (every text file, `bin/run` included, has CRLF line endings), **When** `bundle exec rubocop` runs in it with RuboCop's default settings, **Then**:
     - Standard output: RuboCop's summary line, `no offenses detected`.
     - Standard error: not compared.
     - Exit status: 0
   - And RuboCop's default `Layout/EndOfLine`, style `native`, wants CRLF on Windows; a `bin/run` forced to LF would be reported as `Carriage return character missing`.

---

### User Story 3 - A reviewer without Ruby 3.4 uses Docker (Priority: P2)

A reviewer without Ruby 3.4, or who cannot get `bundle install` working, builds the Docker image from a clean checkout, runs the sample files with the `output` folder mounted so the file stays on their machine and with `TZ` set so the file name carries their local time, and runs the tests in the container ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).

**Why this priority**: Docker is the fallback, not the main way to run (DEC-36), but it must work from a clean checkout before submission.

**Independent Test**: from a clean checkout, with Docker: build the image, run it with no command, run it with `bundle exec rspec`, using the commands the README gives.

**Acceptance Scenarios**:

1. **The image builds from a clean checkout** (NFR-04; DEC-01, DEC-36).
   - **Given** a clean checkout, **When** `docker build -t mable-transfers .` runs in its root, **Then**:
     - Standard output: not compared (BuildKit writes nothing there).
     - Standard error: Docker's build log, not compared exactly; it shows the official Ruby image whose version equals `.ruby-version` and `bundle install` installing the locked gems without changing `Gemfile.lock`.
     - Exit status: 0
2. **The sample files by default, with `output` mounted and `TZ` set** (NFR-04, AC-08.1; DEC-27, DEC-36, DEC-37).
   - **Given** the built image, **When** the README's run command runs it with no command, with the checkout's `output` folder mounted at the container's `output` folder and `TZ` set to the reviewer's time zone (for example `TZ=Australia/Sydney`), **Then**:
     - Standard output: the sample report, where `<run time>` is the local time in that time zone.
     - Standard error: (nothing)
     - Exit status: 0
     - And the sample output file is in the reviewer's own `output/` folder after the container ends.
3. **The tests in the container** (NFR-04; DEC-34, DEC-36, DEC-37).
   - **Given** the built image, **When** the README's test command runs `bundle exec rspec` in it, **Then**:
     - Standard output: RSpec's summary with `0 failures` and a `Randomized with seed` line (random order).
     - Standard error: not compared.
     - Exit status: 0
4. **The log level and exit status pass through Docker** (NFR-04, AC-09.5, AC-09.2; DEC-25, DEC-28).
   - **Given** the built image, **When** it runs with `-e LOG_LEVEL=info` and no command, **Then** standard output is the sample report, the exit status is 0, and standard error is, as in AC-09.5:

     ```
     I, [<timestamp> #<pid>]  INFO -- : Run started: balances data/mable_account_balances.csv, transfers data/mable_transactions.csv
     I, [<timestamp> #<pid>]  INFO -- : Line 1 applied: ************6789 -> ************5665 500.00
     I, [<timestamp> #<pid>]  INFO -- : Line 2 applied: ************5755 -> ************1212 1000.00
     I, [<timestamp> #<pid>]  INFO -- : Line 3 applied: ************5755 -> ************6789 320.50
     I, [<timestamp> #<pid>]  INFO -- : Line 4 applied: ************1234 -> ************5665 25.60
     I, [<timestamp> #<pid>]  INFO -- : Run ended: processed 4, applied 4, rejected 0
     ```

   - **And when** it runs with the command `ruby bin/run -h`, **Then** standard output is (nothing), standard error is exactly the two usage lines in User Story 2, scenario 2, and the exit status of `docker run` is 1.

---

### User Story 4 - Every push runs the tests and the style checker on GitHub (Priority: P1)

Every push to the GitHub repository starts a GitHub Actions run that installs the locked gems on the Ruby version in `.ruby-version`, runs RSpec and RuboCop, and fails if either fails. The reviewer sees the result next to each commit ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-38](../../docs/design-analysis/design-decisions.md#dec-38); page 10 pick 50).

**Why this priority**: CI is the first NFR-04 check, the check NFR-05 and NFR-06 rely on ("RuboCop runs in CI", "CI runs the whole suite"), and what the reviewer sees with the repository (DEC-38).

**Independent Test**: push a branch and read the GitHub Actions run for that commit.

**Acceptance Scenarios**:

1. **A push runs CI and it passes** (NFR-04; DEC-36).
   - **Given** the finished code pushed to GitHub, **When** the push lands, **Then** one workflow run starts for that commit, with one job on the latest Ubuntu runner, using the Ruby version read from `.ruby-version`, and it installs the gems from the committed `Gemfile.lock` unchanged; for `bundle exec rspec` in that run:
     - Standard output: RSpec's summary with `0 failures` and a `Randomized with seed` line (random order).
     - Standard error: not compared.
     - Exit status: 0
   - And, for `bundle exec rubocop` in that run:
     - Standard output: RuboCop's summary line, `no offenses detected`.
     - Standard error: not compared.
     - Exit status: 0
   - And the workflow produces one run for the commit, and its conclusion is success.
2. **A failing check fails the run** (NFR-04; DEC-36).
   - **Given** a commit where a spec fails or RuboCop finds an offence, **When** it is pushed, **Then**, for the failing step (`bundle exec rspec` or `bundle exec rubocop`):
     - Standard output: RSpec's summary with at least one failure, or RuboCop's offence list; not compared exactly.
     - Standard error: not compared.
     - Exit status: non-zero.
   - And later steps are skipped and the run's conclusion is failure (checked by reading the workflow: each command is its own step, and no step ignores errors; no failing commit is pushed to prove it; decided in the run, item 9).
3. **No threshold and no matrix** (NFR-04; DEC-36; page 4 for the coverage minimum; page 10 pick 50 for the matrix and the Ruby version).
   - **Given** the workflow, **When** it is read, **Then** it has no coverage minimum, no operating-system or Ruby-version matrix, and no Ruby version written in it.

---

### User Story 5 - A reviewer finds everything they need in the README (Priority: P1)

A reviewer opens the repository and reads `README.md` first. It tells them how to build, test and run the program (normally, on Windows and with Docker), what the files must look like, what `LOG_LEVEL` and the exit statuses mean, the assumptions, the design reasoning, the test coverage, the known limitations, what a production version would need, and how the solution was built ([DEC-37](../../docs/design-analysis/design-decisions.md#dec-37), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04)).

**Why this priority**: the README is where a reviewer looks first, and DEC-37 lists the questions they are most likely to ask; NFR-04's Windows and Docker targets point to it.

**Independent Test**: the README check: read the README against the checklist in FR-001 to FR-014, follow every command it gives on a clean checkout, and open every link.

**Acceptance Scenarios**:

1. **Every DEC-37 item is there** (DEC-37).
   - **Given** the finished `README.md`, **When** it is checked against FR-001 to FR-014, **Then** every item is present, in the section order FR-001 sets.
2. **Every command works as written** (NFR-04; DEC-37).
   - **Given** a clean checkout, **When** each command in the README is run as written (on Linux or macOS for the plain commands, on Windows for `ruby bin/run`, with Docker for the Docker commands), **Then** each gives the outcome the README says, as in User Stories 1 to 3, and the two argument forms give (AC-09.1, AC-08.1, AC-08.3):
     - `bin/run b.csv t.csv` with copies of the sample files: standard output is the sample report with last line `Output file: output/final_balances_<run time>.csv`; standard error is (nothing); exit status 0.
     - `bin/run b.csv t.csv out/day1.csv` with the same copies: standard output is the sample report with last line `Output file: out/day1.csv`; standard error is (nothing); exit status 0; and `out/day1.csv` equals the sample output file.
3. **Every exact text matches the program** (DEC-22, DEC-25, DEC-26).
   - **Given** the README, **When** its example output, usage message and messages are compared with page 2, **Then** each is character for character the same (the sample report as in AC-08.1, the usage message as in AC-09.2).
4. **The coverage figure is current** (DEC-36).
   - **Given** the submitted commit, **When** `bundle exec rspec` runs on it, **Then**:
     - Standard output: RSpec's summary with `0 failures`, and SimpleCov's `Line Coverage: <percent>% (<covered> / <total>)` line, equal character for character to the README's line.
     - Standard error: not compared.
     - Exit status: 0
5. **Every link resolves** (DEC-37, DEC-38).
   - **Given** the README on GitHub, **When** each relative link is followed, **Then** it opens a file or folder that exists in the repository.

---

### User Story 6 - The submission holds everything needed and nothing generated (Priority: P2)

The solution is submitted as a link to the GitHub repository, made public or shared with the reviewer at submission time. The pushed repository holds the code, the tests, the tooling files, the sample data and the documents, keeps the challenge files unchanged, holds nothing a run generates, and shows a passing CI run ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04)).

**Why this priority**: it is the last step before the developer submits; most of it is already true once Stories 1 to 5 hold.

**Independent Test**: the submission check (FR-026 to FR-029) on the pushed branch, with `git ls-files`, `git diff` and the GitHub Actions page.

**Acceptance Scenarios**:

1. **What the repository holds** (DEC-38, DEC-01).
   - **Given** the pushed branch, **When** `git ls-files` lists it, **Then** it includes `README.md`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.gitignore`, `.rspec`, `.rubocop.yml`, `Dockerfile`, the workflow file, `bin/run`, the code folders, `spec/` (with `spec/fixtures/sample/`), `data/mable_account_balances.csv`, `data/mable_transactions.csv`, `docs/` and `specs/`.
2. **Nothing generated** (DEC-27, DEC-36).
   - **Given** the same listing, **When** it is searched, **Then** no path is under `output/` or `coverage/`, and `git status` on a checkout after a run and a test run shows no untracked file.
3. **The challenge files are unchanged** (CLAUDE.md, DEC-22).
   - **Given** the pushed branch, **When** `docs/challenge/` is compared with the commit that added it, **Then** there is no difference, and `data/` and `spec/fixtures/sample/` hold byte-for-byte copies of the two CSV files.
4. **CI is green and making the repository public is left to the developer** (DEC-36, DEC-38).
   - **Given** the pushed branch, **When** its latest commit's GitHub Actions run is read, **Then** its status is success; making the repository public, or sharing it with the reviewer, is listed in the run report as left for the developer.

---

### Edge Cases

- **Docker with no `TZ`** (DEC-37; page 9 risks): the container uses UTC, so the file name carries the UTC time; the run is otherwise the same. The README says to set `TZ`.
- **Docker with no `output` mount** (DEC-37): the file is written inside the container and is lost when the container is removed; standard output still shows the report. The README gives the mount in its run command.
- **Docker with a mount and an existing file of the same name** (DEC-25, DEC-27): the run stops at the start checks, as AC-09.3 states, and the reviewer's file is unchanged.
- **Docker with typed paths** (DEC-22): files outside the image must be mounted; the README's commands use only the sample files, and a reviewer passing their own files mounts them the same way as `output`. The README says so in one line (decided in the run, item 6).
- **A lock file made on Windows** (DEC-01): `Gemfile.lock` must also list the Linux platforms CI and Docker use, or a frozen install there fails (decided in the run, item 4).
- **`bin/run` on Linux and macOS** (DEC-22): it must start as `bin/run`, so it is committed as executable, starts with `#!/usr/bin/env ruby` (added here if `002` left it out, decided in the run, item 16) and is stored with LF line endings in Git (decided in the run, item 7). On Windows and in a Docker container it is run as `ruby bin/run`.
- **Line endings in a Windows checkout** (DEC-04): Git may give text files CRLF line endings on Windows; the CSV library reads them the same, and the output file is LF on every system (page 10 pick 17). `bin/run` is not treated differently: it too gets CRLF in a Windows checkout made with `core.autocrlf=true`, which is what RuboCop's default `Layout/EndOfLine` (`native`, CRLF on Windows) requires, so `bundle exec rubocop` reports no offence there (FR-018; decided in the run, item 17). A kernel cannot start a CRLF `#!/usr/bin/env ruby` line ("No such file or directory"), so nothing here starts `bin/run` through its shebang on Windows or in Docker: Windows runs `ruby bin/run`, and the Docker image runs `ruby bin/run`, which ignores the line ending of that line. There is no `.gitattributes` file.
- **Docker on a Linux host** (DEC-36, DEC-37): the container runs as the image's default user, root, so the file it writes in the mounted `output/` folder may belong to root; the README says so in one line, and the run command adds no `--user` option (Clarifications).
- **A Windows reviewer with Docker Desktop** (DEC-37): the mount path differs between shells, so the README gives the Docker run command for a POSIX shell and for PowerShell (decided in the run, item 5).
- **A run from another folder on Windows** (DEC-22, DEC-26): `ruby ..\bin\run` from `docs` shows `Output file: ../output/final_balances_<run time>.csv`, as in AC-08.4.
- **No Ruby 3.4 on the Windows machine used for the check, or no Docker** (brief Part 2 step 3): the hand check that cannot be run is listed in the run report as left for the developer, never marked as passed.
- **A newer Ruby 3.4.x released after `.ruby-version` is set** (DEC-01): `.ruby-version` and the Dockerfile keep the same version; the version is changed in both at once, never in one.

## Requirements *(mandatory)*

### Functional Requirements

Each requirement cites the NFR or decision it serves. The README requirements (FR-001 to FR-014) are what the README check reads against.

**The README ([DEC-37](../../docs/design-analysis/design-decisions.md#dec-37))**

- **FR-001** (DEC-37, NFR-04; DEC-01, DEC-22): `README.md` at the repository root MUST give the build, test and run instructions first: the normal way (Ruby at the version in `.ruby-version`, `bundle install`, then `bin/run`; `bundle exec rspec` for the tests and `bundle exec rubocop` for the style check), then Docker as the alternative (FR-005). The README's sections MUST follow DEC-37's order: build, test and run (the normal way, Windows, then Docker; FR-001 to FR-005); the input files (FR-006); `LOG_LEVEL` and exit statuses (FR-007, FR-008); the assumptions (FR-009); the design reasoning (FR-010); the test coverage (FR-012); persistent storage, production items and known limitations (FR-011); "How this was built" (FR-013); then the repository layout and the link to the challenge (FR-014) (Clarifications).
- **FR-002** (DEC-37, DEC-22; AC-09.1, AC-09.2): the run instructions MUST show `bin/run` with no arguments (the sample files in `data/`, output in `output/`), with 2 arguments and with 3 arguments, as in the AC-09.1 table; that typed paths are relative to the current folder and default paths to the project root; the default output name `output/final_balances_YYYY-MM-DD_HHMMSS.csv` from the local time the run started, and that an existing output file is never overwritten (DEC-25, DEC-27); and the usage message exactly as in AC-09.2.
- **FR-003** (DEC-37, DEC-35; AC-08.1): the README MUST show the sample run's report exactly as in AC-08.1 (with the run time of page 2), so a reviewer can compare their own run with it (decided in the run, item 8).
- **FR-004** (DEC-37, NFR-04): the README MUST say that on Windows the program runs as `ruby bin/run` (with the same arguments).
- **FR-005** (DEC-37, DEC-36, NFR-04): the Docker instructions MUST give the command to build the image, the command to run the program with the checkout's `output` folder mounted at the container's `output` folder and `TZ` set, for a POSIX shell and for PowerShell, and the command to run the tests in the container; and MUST say that the container uses UTC for the file name unless `TZ` is set, and that the mount keeps the output CSV on the reviewer's machine; and MUST say in one line that on a Linux host the output file may belong to root, because the container runs as the image's default user (Clarifications). The run command MUST NOT add a `--user` option.
- **FR-006** (DEC-37, DEC-04, DEC-06): the README MUST describe both file formats (`account number,balance` and `from account number,to account number,amount`, CSV), and say that files must have no header and that a header row is a bad row.
- **FR-007** (DEC-37, DEC-28, DEC-29): the README MUST explain `LOG_LEVEL`: `warn` (the default) and `info`, in any letter case, any other value falling back to `warn`; that log lines go to standard error with account numbers masked as `************6789`; and that the report alone goes to standard output.
- **FR-008** (DEC-37, DEC-25; AC-09.8): the README MUST say that exit status 0 means the run completed, even if some or all transfers were rejected, and 1 means the run stopped, listing the reasons in AC-09.8.
- **FR-009** (DEC-37; [Assumptions](../../docs/design-analysis/design-decisions.md#assumptions)): the README MUST list the ten assumptions of `design-decisions.md`, each with its reason, worded as there (decided in the run, item 10).
- **FR-010** (DEC-37, DEC-30, DEC-31, DEC-18, DEC-09): the README MUST explain the design reasoning: light domain-driven design with the rules inside the models, the three folders `domain`, `application` and `infrastructure`, the in-memory `AccountRepository`, the parts passed in to `ProcessDailyTransfer`, every check before any balance changes, and money as `Money` on `BigDecimal`; and MUST link to `design-decisions.md` and the solution design for the rest. The design reasoning is in the README, not in code comments.
- **FR-011** (DEC-37, DEC-03, DEC-18, DEC-32; page 9 risks, page 10 known limitations): the README MUST give (a) what a version with persistent storage would need to stay idempotent (remembering which files and transfers were applied, so a rerun cannot apply a day twice), and that remembering applied files across runs is out of scope; (b) the production items: very large files (streaming or chunking), and a database repository with database transactions or sagas; (c) the known limitations from page 9's risks table and page 10, each in one line (decided in the run, item 11).
- **FR-012** (DEC-36): the README MUST show the test coverage figure as SimpleCov prints it for line coverage after a full `bundle exec rspec` run on the final code (the percentage and the covered and total line counts), say that the full report is in `coverage/index.html` after a test run, and state no minimum.
- **FR-013** (DEC-37, CLAUDE.md "Prompt log"): the README MUST have a "How this was built" section that says the design and code were made with an AI assistant, and lists the four steps (design analysis, solution design, GitHub Spec Kit specification, test-first implementation through the Spec Kit tasks), each with a link to its documents: `docs/design-analysis/design-decisions.md`, `docs/solution-design/README.md`, `.specify/memory/constitution.md` and `specs/`, and the prompt logs in `docs/prompts/` (decided in the run, item 12).
- **FR-014** (DEC-37, DEC-38): the README MUST keep a link to the challenge in `docs/challenge/` and a repository layout table updated for the finished repository, and MUST replace the current "Status" and "To be added" sections; it MUST NOT name the company whose balances are processed ([DEC-02](../../docs/design-analysis/design-decisions.md#dec-02)); the challenge's own name is kept in the title and the challenge link (plan item 11).

**Language version and portability ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04))**

- **FR-015** (NFR-04; DEC-01): the Ruby version in the Dockerfile's base image MUST be exactly the version in `.ruby-version` (built by `001`), the latest Ruby 3.4.x release; when one changes, both change in the same commit.
- **FR-016** (NFR-04; DEC-01): the runtime code MUST use only Ruby's standard library and the gems `csv`, `bigdecimal` and `logger`; the development gems MUST be only `rspec`, `simplecov`, `rubocop` and `rubocop-rspec`, and only inside the Gemfile's development/test group, so the program itself needs only the standard library and `csv`, `bigdecimal` and `logger`, and the tools are needed only for development (NFR-04; 001 FR-037; checked here; built by `001`).
- **FR-017** (NFR-04; DEC-01; decided in the run, item 4): the committed `Gemfile.lock` MUST install unchanged, with Bundler's frozen setting, on Windows, on the CI runner and in the Docker image; it MUST list the platforms needed for that (the plan picks them).
- **FR-018** (NFR-04; DEC-22; decided in the run, item 7): `bin/run` (built by `002`; its mode and first line are requirements this spec adds and checks, decided in the run, item 16) MUST be stored in Git as executable, begin with `#!/usr/bin/env ruby`, and have LF line endings in the repository (the index), so it starts as `bin/run` on Linux and macOS (whose checkouts are LF), and as `ruby bin/run` on Windows and in Docker. Every text file in the repository MUST be stored with LF line endings. The repository MUST NOT hold a `.gitattributes` file that changes how any file is checked out: a Windows checkout made with `core.autocrlf=true` gives every Ruby file, `bin/run` included, CRLF, and `bundle exec rubocop` MUST report `no offenses detected` (exit status 0) in that checkout, with RuboCop's default settings (DEC-36; NFR-05; decided in the run, item 17; Clarifications).
- **FR-019** (NFR-04; DEC-04, DEC-22, page 3): the NFR-04 targets built in `001` and `002` MUST hold, checked by design review: files are read only through Ruby's CSV library (CRLF, a missing final newline and a byte-order mark give the same result, the last proved by `002`'s fixture test); default paths are found from the project root (AC-08.4, proved by `002`); one command runs the program after `bundle install`.

**CI ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36))**

- **FR-020** (NFR-04; DEC-36; page 10 pick 50; decided in the run, item 9): a GitHub Actions workflow, `.github/workflows/ci.yml`, MUST run on every push to any branch, with one job on the latest Ubuntu runner, set up Ruby from `.ruby-version`, install the gems from `Gemfile.lock`, and run `bundle exec rspec` and `bundle exec rubocop` as separate steps; the run MUST fail if either exits non-zero.
- **FR-021** (NFR-04; DEC-36; page 4 for the coverage minimum; page 10 pick 50 for the matrix and the Ruby version): the workflow MUST NOT set a coverage minimum, an operating-system or Ruby-version matrix, or a Ruby version of its own, and MUST add no step beyond checking out the code, setting up Ruby, installing the gems and the two checks.

**Docker ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36))**

- **FR-022** (NFR-04; DEC-01, DEC-36; decided in the run, item 5): a `Dockerfile` at the repository root MUST build from the official Ruby image of exactly the `.ruby-version` version (the full image, not a slim one), copy the project in, run `bundle install` from the committed `Gemfile.lock`, and by default run `bin/run` with no arguments, directly and not through `bundle exec`, as its default command in exec form (`CMD ["ruby", "bin/run"]`), so a container started with no command runs the sample files, the exit status of `docker run` is the program's, an image built from a Windows checkout (where `bin/run` may have CRLF line endings) still starts it, and a command given after the image name (such as `bundle exec rspec` or `ruby bin/run -h`) replaces it (Clarifications; decided in the run, item 17).
- **FR-023** (NFR-04; DEC-36, DEC-37): in the container, the working folder MUST be the project root, so the report shows `Output file: output/final_balances_<run time>.csv`, the log shows `data/...` paths as in AC-09.5, and the README's mount of `output` receives the file; `bundle exec rspec` MUST run in the image and pass.
- **FR-024** (NFR-04; DEC-36; decided in the run, item 13): the Dockerfile MUST add nothing else: no extra system packages, no other gems, no change to the program's behaviour, and no `.dockerignore` (a clean checkout has no `output/` or `coverage/`).

**The checks before submission ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04))**

- **FR-025** (NFR-04; DEC-36, DEC-37; page 10 pick 20): before submission, from a clean checkout of the pushed branch: (a) the Docker image MUST be built, the sample files run in it (User Story 3, scenarios 2 and 4) and the tests run in it (scenario 3); (b) on Windows, in a clone made with `core.autocrlf=true`, `bundle install` and `ruby bin/run` MUST give the sample report and the sample output file, and `bundle exec rubocop` MUST report `no offenses detected` with exit status 0 (User Story 2, scenarios 1 to 4); (c) on Linux or macOS, or in a Linux container from the official `ruby:<version>` image with the clean checkout mounted, `bin/run` MUST give the same (User Story 1). Each result is recorded in the run report; a check that cannot be run on the machine at hand is listed there as left for the developer.

**The submission ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38))**

- **FR-026** (DEC-38, DEC-01, DEC-22, DEC-34): the pushed repository MUST hold every file in User Story 6, scenario 1, and the code under the folder layout `001` sets.
- **FR-027** (DEC-27, DEC-36): the pushed repository MUST NOT hold any file under `output/` or `coverage/`, and a run and a test run on a checkout MUST leave `git status` clean (both folders are in `.gitignore`, built by `001`).
- **FR-028** (CLAUDE.md, DEC-22, DEC-34): `docs/challenge/` MUST be unchanged since the commit that added it; `data/` and `spec/fixtures/sample/` MUST hold byte-for-byte copies of its two CSV files; this spec adds no other test-data file.
- **FR-029** (DEC-36, DEC-38): the latest commit of the pushed branch, `main`, MUST have a successful GitHub Actions run. Making the repository public or sharing it with the reviewer is done by the developer at submission time and is listed in the run report as left for the developer.
- **FR-030** (brief rule 4): this spec MUST add no RSpec spec, no class and no change to the program's behaviour; it is checked by CI, a Docker run, a Windows run, the README check and the submission check.

### Key Entities *(include if feature involves data)*

Names and meanings as in the [page 10 glossary](../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary).

- **README** (`README.md`): the reviewer's starting page; its content is FR-001 to FR-014.
- **Coverage figure**: SimpleCov's line coverage from a full test run on the final code, shown in the README (DEC-36).
- **CI workflow** (`.github/workflows/ci.yml`): the GitHub Actions workflow that runs RSpec and RuboCop on every push (DEC-36).
- **Dockerfile**: builds the Docker image, the fallback way to run (DEC-36).
- **Clean checkout**: a fresh clone of the pushed branch in a new, empty folder (Conventions).
- **Submission**: the link to the GitHub repository (DEC-38).
- Changed here: `Gemfile.lock` (platforms added, gem versions unchanged, FR-017); `bin/run` (Git mode set to 100755 if needed, and the first line `#!/usr/bin/env ruby` added if missing, the rest of the content unchanged except, only if RuboCop then reports it, the `# frozen_string_literal: true` comment on line 2, spec item 16; FR-018).
- Used from `001` and `002`, unchanged: `.ruby-version`, `Gemfile`, `.gitignore`, `.rspec`, `.rubocop.yml`, `Runner`, `data/`, `spec/fixtures/sample/`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** (NFR-04; DEC-35): on each of three platforms (Linux or macOS, or a Linux container from the official `ruby:<version>` image with the clean checkout mounted; Windows; Docker), the sample run from a clean checkout gives the sample report on standard output, nothing on standard error, exit status 0, and the sample output file byte for byte: 3 of 3 (any platform that cannot be run is listed as left for the developer, never counted as passed).
- **SC-002** (NFR-04; DEC-36): 100% of the GitHub Actions runs on the pushed branch's latest commit succeed, with 0 test failures and 0 style offences.
- **SC-003** (DEC-37): the README check finds every item of FR-001 to FR-014: 14 of 14, and every command and every relative link in the README works on a clean checkout.
- **SC-004** (DEC-36): the coverage figure in the README equals the figure a fresh test run prints on the submitted commit.
- **SC-005** (NFR-04; DEC-01): `.ruby-version` and the Dockerfile name the same Ruby version, and `Gemfile.lock` installs unchanged on all three platforms.
- **SC-006** (DEC-38, DEC-27, DEC-36): the pushed repository holds 0 files under `output/` or `coverage/`, and `docs/challenge/` shows 0 changed bytes.
- **SC-007** (brief rule 4): this spec adds 0 RSpec specs, 0 classes and 0 test-data files.

## Assumptions

- The assumptions in [`design-decisions.md`](../../docs/design-analysis/design-decisions.md#assumptions) hold; in particular the reviewer has Ruby 3.4, or Docker (DEC-36).
- `001-domain` and `002-file-runner` are finished before this spec is built: the skeleton, `bin/run`, `data/` and the tests are as their specs state. The README can only be finished once both are ([brief rule 3](../../docs/spec-kit/spec-kit-brief.md#3-specs)).
- The GitHub repository is `origin` (`hetal-patel78/mable-backend-code-challenge`) and GitHub Actions is enabled on it.
- The Windows check is run on the developer's Windows machine, and the Docker check wherever Docker is available; if either cannot be run, it is left for the developer (brief Part 2, step 3).
- Out of scope: a coverage threshold, a help option, logging to a file or service ([page 4](../../docs/solution-design/04-scope.md#out-of-scope)); a CI matrix over operating systems or Ruby versions (page 9 "Portability and CI", page 10 pick 50); Docker as the main way to run (DEC-36); any gem beyond those DEC-01 and DEC-36 name (DEC-01, DEC-36). Nothing in this spec changes what the program does.

## Decided in the run

Small gaps decided while writing this spec, consistent with `design-decisions.md`. Each is for the developer's review.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| 1 | In runs made by hand or by CI, `<run time>` stands for the real run time in the output file name and the `Output file:` line; nothing else may differ from page 2 | NFR-04, AC-08.1, DEC-27, DEC-30 | Page 2 fixes the run time for its examples; a hand run cannot, and the program takes no run time from outside (DEC-30 rejects a `RUN_DATE` setting) | Comparing only the closing balances; adding a way to set the run time |
| 2 | A clean checkout is a fresh `git clone` of the pushed branch into a new, empty folder outside the working repository | NFR-04, DEC-36 | Proves the pushed files alone are enough, with no `output/`, `coverage/` or installed gems left from development; outside the repository, as `CLAUDE.md` requires for extra working folders | A `git worktree` (shares the repository); `git clean` in the working copy (can miss ignored files the developer needs) |
| 3 | On Windows the `Output file:` line uses `/`, exactly as on page 2 | NFR-04, DEC-26, AC-08.1 | Ruby's paths use `/` on every system, so the report is the same everywhere and the page 2 text is kept | `\` on Windows (the report would differ by system) |
| 4 | `Gemfile.lock` lists the platforms needed to install unchanged, frozen, on Windows, the Ubuntu CI runner and the Docker image; the plan picks the platform list | DEC-01, NFR-04 | A lock file made on Windows lists only the Windows platform, and a frozen install on Linux then fails; DEC-01 commits the lock file so every machine installs the same gems | Not freezing the install in CI and Docker (versions could drift); not committing the lock file (rejected by DEC-01) |
| 5 | The Docker image is named `mable-transfers`, built from the full official `ruby:<version>` image (not slim), with the project root as its working folder; the README gives the run command for a POSIX shell and for PowerShell | DEC-36, DEC-37 | One name for every README command; the full image has the build tools a gem with a native part may need and the time-zone data `TZ` needs; the mount path is written differently in the two shells | A slim image (may lack build tools or time-zone data); one shell's syntax only; no fixed name |
| 6 | The README says in one line that a reviewer's own files must be mounted into the container like `output` | DEC-22, DEC-37 | Typed paths are read inside the container; without the line a reviewer's first own-file run would fail with "file not found" | Leaving it out; a second mounted folder in the default command |
| 7 | `bin/run` is stored executable in Git, starts with `#!/usr/bin/env ruby` and has LF line endings in the index (item 17 explains why no `.gitattributes` forces LF in checkouts); every text file is stored with LF | DEC-22, NFR-04 | Linux and macOS start `bin/run` directly, which needs the executable mode and the line (their checkouts are LF); the repository already stores LF | Running `ruby bin/run` everywhere (the README's normal command on Linux and macOS is `bin/run`) |
| 8 | The README shows the sample run's report exactly as in AC-08.1, with page 2's run time | DEC-37, DEC-35 | A reviewer can check their own run against it; using page 2's text keeps one copy of the expected output | No example output; a different run time |
| 9 | The CI workflow is `.github/workflows/ci.yml`, triggered on push to any branch, with RSpec and RuboCop as separate steps; "a failing check fails the run" is checked by reading the workflow, not by pushing a failing commit | DEC-36, page 10 pick 50 | DEC-36 says every push; separate steps show which check failed; a deliberately failing push would add a broken commit to the history reviewers read | A pull-request trigger as well (not asked); one combined step; a failing test commit |
| 10 | The README lists the ten assumptions with their reasons, worded as in `design-decisions.md`, linking there for the decisions | DEC-37, Assumptions | One wording for every assumption, so the README and the decisions cannot disagree | Shortened wording; only a link |
| 11 | The README gives the known limitations from page 9's risks table and page 10, each in one line | DEC-37, page 9, page 10 | The brief gives page 10's known limitations to this spec; a reviewer asks about them next to the production items | Leaving them in the solution design only |
| 12 | "How this was built" names the AI assistant and the four steps of `CLAUDE.md`'s development approach, with links to each step's documents and to `docs/prompts/` | DEC-37, CLAUDE.md, brief rule 3 | The brief names this section; the prompt logs exist so a reviewer can see how the design and code were shaped | A separate document; no links |
| 13 | No `.dockerignore`; the Dockerfile adds nothing beyond DEC-36 | DEC-36, page 4 | A clean checkout holds no generated folders, and nothing else is asked for | A `.dockerignore` (one more file with no stated need) |
| 14 | The README keeps the challenge link and a repository layout table updated for the finished repository, and replaces the "Status" and "To be added" sections | DEC-37, CLAUDE.md "Submission" | The current README is a placeholder from the design analysis; the layout helps a reviewer find the documents | Removing the layout table; keeping the design-analysis status text |
| 15 | On Windows the console streams (standard output and standard error) use CRLF line endings, because Ruby writes them in text mode; they are compared line by line with CRLF changed to LF. The output CSV is written with LF and compared byte for byte | AC-08.3; DEC-22, DEC-35; page 10 pick 17 | The program writes LF everywhere; only the Windows console layer adds CR, which is not a defect in `002` | Comparing the console streams byte for byte (fails on Windows for a reason that is not a defect); changing `002` to write binary |
| 16 | `002-file-runner` builds `bin/run` with the first line `#!/usr/bin/env ruby`, the `# frozen_string_literal: true` comment and mode `100755` (002 plan P26; 002 tasks T036). This spec checks them as NFR-04 targets (C-01, C-43) and keeps a fix-only-if-missing step as a safeguard: if C-01 finds the mode or first line missing or different, this spec sets it, as the only content change to `bin/run` apart from one more: `bundle exec rubocop bin/run` is run, and if it reports an offence the only extra change allowed is the `# frozen_string_literal: true` comment on line 2; any other offence is reported as a cross-spec finding against `002-file-runner` and fixed there test-first; the program code is not touched | DEC-22, NFR-04 | Without the line and the mode, `bin/run` cannot start as `bin/run` on Linux or macOS, and NFR-04 requires the run to work from a clean checkout, so a miss must be fixed whichever spec missed it | Reporting a missing line or mode against `002` and fixing it there (a delay for a one-line fix, when the safeguard already covers it) |
| 17 | No `.gitattributes` file is created, and `bin/run` is not forced to LF in checkouts. The Dockerfile's default command is `CMD ["ruby", "bin/run"]` (exec form), and the README and the checks run `bin/run` inside the container as `ruby bin/run ...`. A check runs `bundle exec rubocop` in the fresh `core.autocrlf=true` Windows clone and expects `no offenses detected`, exit status 0 | DEC-36, DEC-22, NFR-04, NFR-05 | With `bin/run` under RuboCop (item 16) and Git giving every Ruby file CRLF on Windows, RuboCop's default `Layout/EndOfLine` (`native`: CRLF on Windows, LF elsewhere) reports `Carriage return character missing` for a `bin/run` forced to LF, and DEC-36 forbids changing RuboCop's settings. Ruby ignores the line ending of a `#!` line, so `ruby bin/run` starts whatever the line ending. Research note (checked against the published gem source): `rubocop-rspec`'s own `config/default.yml` excludes `**/*_spec.rb` and `**/spec/**/*` from `Metrics/BlockLength`, so spec files are not checked by it and zero offences is reachable under DEC-36's default settings; no change to DEC-36 is needed | `* text=auto eol=lf` or `bin/run text eol=lf` in `.gitattributes` (breaks zero offences on Windows); `# rubocop:disable Layout/EndOfLine` in `bin/run`, or a `.rubocop.yml` change (against DEC-36's default settings, and `.rubocop.yml` belongs to `001`); `CMD ["bin/run"]` (fails from a Windows checkout with a CRLF shebang) |
