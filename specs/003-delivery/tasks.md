---
description: "Task list for 003-delivery: README, CI, Docker and the submission"
---

# Tasks: Delivery: README, CI, Docker and the submission

**Input**: Design documents from [`specs/003-delivery/`](/): [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Prerequisites**: `001-domain` and `002-file-runner` are implemented on the branch this work starts from ([brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) step 2).

**Tests**: this spec adds no RSpec spec ([brief rule 4](../../docs/spec-kit/spec-kit-brief.md#4-how-the-tests-are-split); [FR-030](spec.md#fr-030)). Its tests are the checks [C-01](quickstart.md#c-01) to [C-43](quickstart.md#c-43) in [quickstart.md](quickstart.md). In every phase the check comes first: run it, see it fail (or, for a phase that adds no file, see that it exists and is ready), then make the change, then run it again until it passes. Every phase ends with its checks passing, `bundle exec rspec` passing in random order and `bundle exec rubocop` reporting no offences ([constitution](../../.specify/memory/constitution.md), Development workflow). Each result is recorded in [`docs/spec-kit/implementation-run-report.md`](../../docs/spec-kit/implementation-run-report.md) (Part 2 section) with the platform, date, commit and evidence; a check that cannot run on the machine at hand is recorded as left for the developer, never as passed ([FR-025](spec.md#fr-025); [C-28](quickstart.md#c-28)).

**Organization**: by user story, in the order the files depend on each other: the repository files, then CI ([US4](spec.md#us4)), the Ruby runs ([US1](spec.md#us1), [US2](spec.md#us2)), Docker ([US3](spec.md#us3)), the README ([US5](spec.md#us5), which needs the commands and the coverage figure proved first), then the push and the submission ([US6](spec.md#us6)).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an unfinished task).
- **[Story]**: the user story in [spec.md](spec.md) ([US1](spec.md#us1) to [US6](spec.md#us6)).
- `$REPO` is the working repository root; `$CHECKS` is a scratch folder outside it; `$CLEAN` is a clean checkout ([quickstart.md](quickstart.md#prerequisites)).
- Commit in small steps, only the files changed, by explicit path, each message naming what it covers.

---

<a id="phase-1"></a>
## Phase 1: Setup

**Purpose**: confirm what this spec builds on, and prepare the expected texts the checks compare.

- [X] <a id="t001"></a>T001 At `$REPO`, run `bundle exec rspec` (0 failures, `Randomized with seed`) and `bundle exec rubocop` (no offences), and record both in [`docs/spec-kit/implementation-run-report.md`](../../docs/spec-kit/implementation-run-report.md) as the starting point ([NFR-05](../../docs/solution-design/03-non-functional-requirements.md#nfr-05), [NFR-06](../../docs/solution-design/03-non-functional-requirements.md#nfr-06); [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)). If either fails, stop: the defect belongs to `001-domain` or `002-file-runner`.
- [X] <a id="t002"></a>T002 Read [`.ruby-version`](../../.ruby-version) and record the exact version in the run report; check it is a bare version number such as `3.4.12` (as pinned by `001` plan [D1](../001-domain/plan.md#d1)) and the latest Ruby 3.4.x release ([FR-015](spec.md#fr-015); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01); [plan item 1](plan.md#item-1)). A `ruby-` prefix is reported as a cross-spec finding against `001-domain` [FR-036](../001-domain/spec.md#fr-036), not worked around.
- [X] <a id="t003"></a>T003 [P] Create `$CHECKS` outside the repository (and, for the Windows checks, the PowerShell `$env:CHECKS` folder from the quickstart Prerequisites) and save the expected texts listed in [quickstart.md](quickstart.md#expected-texts): `report.txt` (the sample report, [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1) with `<run time>`), `final.csv` (the sample output file, LF, final LF), `usage.txt` ([AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2)), `info.txt` ([AC-09.5](../../docs/solution-design/02-functional-requirements.md#ac-09-5)), copied character for character from [spec.md](spec.md#conventions-used-in-the-scenarios) ([DEC-35](../../docs/design-analysis/design-decisions.md#dec-35), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28)).

**Checkpoint**: the suite and RuboCop pass; the expected texts are ready.

---

<a id="phase-2"></a>
## Phase 2: Foundational: the repository files (FR-016, FR-017, FR-018)

**Purpose**: what CI, Docker and the Windows run all depend on: [`bin/run`](../../bin/run) stored so it starts on Linux and macOS (and run as `ruby bin/run` on Windows and in Docker), no `.gitattributes` ([spec item 17](spec.md#item-17)), and a [`Gemfile.lock`](../../Gemfile.lock) that installs unchanged on every platform. Blocks every user story.

### Checks first

- [X] <a id="t004"></a>T004 At `$REPO`, run [C-01](quickstart.md#c-01), [C-02](quickstart.md#c-02), [C-03](quickstart.md#c-03) and [C-05](quickstart.md#c-05) ([quickstart.md](quickstart.md#repository-files-foundational)) and record the results before any change: [C-02](quickstart.md#c-02) already passes (there is no `.gitattributes`) and must keep passing, and [C-03](quickstart.md#c-03) must fail (the `PLATFORMS` list lacks the six platforms of [repository-files.md](contracts/repository-files.md#gemfilelock)) ([FR-016](spec.md#fr-016) to [FR-018](spec.md#fr-018); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)).

### Implementation

- [X] <a id="t005"></a>T005 Do not create a `.gitattributes` file: a LF-forced [`bin/run`](../../bin/run) would be reported by RuboCop's default `Layout/EndOfLine` (`native`) on every Windows checkout, and [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36) forbids changing RuboCop's settings. Confirm `test ! -e .gitattributes` ([C-02](quickstart.md#c-02)); if another spec added one, remove it and report it as a cross-spec finding ([FR-018](spec.md#fr-018); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); spec [Clarifications](spec.md#clarifications) and [item 17](spec.md#item-17)).
- [X] <a id="t006"></a>T006 If [C-01](quickstart.md#c-01) showed a mode other than `100755`, run `git update-index --chmod=+x bin/run` (content unchanged; [plan item 14](plan.md#item-14)). If [C-01](quickstart.md#c-01) showed a first line other than `#!/usr/bin/env ruby`, make that line the first line of [`bin/run`](../../bin/run) (add it if missing, replace a different interpreter line) and change nothing else in the file yet; `002-file-runner` already builds [`bin/run`](../../bin/run) with that line, the line-2 comment and mode `100755` (002 plan [P26](../002-file-runner/plan.md#p26); 002 tasks [T036](../002-file-runner/tasks.md#t036)), so these fixes are a safeguard that applies only if [C-01](quickstart.md#c-01) or [C-43](quickstart.md#c-43) finds one missing ([spec item 16](spec.md#item-16); [FR-018](spec.md#fr-018); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)). Run `bundle exec rubocop bin/run` (RuboCop inspects an extensionless file only when its first line is a Ruby shebang). If it reports an offence, the only extra change allowed is the one RuboCop needs, the `# frozen_string_literal: true` magic comment on line 2; any other offence in [`bin/run`](../../bin/run) is reported as a cross-spec finding against `002-file-runner` and fixed there test-first, not here. Then re-run `bundle exec rspec` to confirm the end-to-end runs still pass. If [C-01](quickstart.md#c-01) listed a file this spec owns under [`docs/`](../../docs/) or [`specs/`](../) with `i/crlf`, renormalize that file to LF in the index ([FR-018](spec.md#fr-018); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04); [plan item 13](plan.md#item-13)). An `i/crlf` file under [`lib/`](../../lib/), [`spec/`](../../spec/), [`data/`](../../data/), [`bin/run`](../../bin/run) or another spec's files is reported as a cross-spec finding and fixed in `001-domain` or `002-file-runner`, not here ([FR-030](spec.md#fr-030); [C-34](quickstart.md#c-34)). An `i/crlf` file under [`docs/challenge/`](../../docs/challenge/) is reported as a blocker, because [`docs/challenge/`](../../docs/challenge/) is never edited.
- [X] <a id="t007"></a>T007 Run `bundle lock --add-platform ruby x64-mingw-ucrt x86_64-linux aarch64-linux x86_64-darwin arm64-darwin` at `$REPO`, then `git diff Gemfile.lock`: only the `PLATFORMS` section (and, where Bundler lists a gem per platform, new lines for the same versions) may change; no gem version changes ([FR-017](spec.md#fr-017); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01); [plan item 2](plan.md#item-2)). Do not change [`Gemfile`](../../Gemfile) ([FR-016](spec.md#fr-016), checked by [C-05](quickstart.md#c-05)).
- [X] <a id="t008"></a>T008 Re-run [C-01](quickstart.md#c-01), [C-02](quickstart.md#c-02), [C-03](quickstart.md#c-03) and [C-05](quickstart.md#c-05) (all pass), then `bundle exec rspec` and `bundle exec rubocop` (zero offences, now including [`bin/run`](../../bin/run)); record the results and commit [`Gemfile.lock`](../../Gemfile.lock) and, if changed, [`bin/run`](../../bin/run) (its mode, its first line if it was missing or different, and the line-2 comment if [T006](#t006) added it), by explicit path.

**Checkpoint**: [C-01](quickstart.md#c-01), [C-02](quickstart.md#c-02), [C-03](quickstart.md#c-03) and [C-05](quickstart.md#c-05) pass; the suite and RuboCop still pass.

---

<a id="phase-3"></a>
## Phase 3: User Story 4 - Every push runs the tests and the style checker on GitHub (Priority: P1)

**Goal**: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) runs RSpec and RuboCop on every push, one job on the latest Ubuntu runner, Ruby from [`.ruby-version`](../../.ruby-version) ([FR-020](spec.md#fr-020), [FR-021](spec.md#fr-021); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [page 10 pick 50](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50)).

**Independent Test**: [C-06](quickstart.md#c-06) by reading the file; [C-07](quickstart.md#c-07) once the branch is pushed ([T049](#t049)).

### Checks first

- [X] <a id="t009"></a>T009 [[US4](spec.md#us4)] Run [C-06](quickstart.md#c-06) ([quickstart.md](quickstart.md#ci-user-story-4)) at `$REPO` and record that it fails: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) does not exist ([FR-020](spec.md#fr-020)).

### Implementation

- [X] <a id="t010"></a>T010 [[US4](spec.md#us4)] Create [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) exactly as [contracts/ci-workflow.md](contracts/ci-workflow.md): `name: CI`; `on: push` with no branch filter; one job `checks` on `ubuntu-latest`; steps `Check out the code` (`actions/checkout@v5`), `Set up Ruby` (`ruby/setup-ruby@v1` with no inputs), `Install the gems` (`bundle install` with `env: BUNDLE_FROZEN: "true"`), `Run RSpec` (`bundle exec rspec`), `Run RuboCop` (`bundle exec rubocop`); no matrix, no `ruby-version`, no `bundler-cache`, no `continue-on-error`, no coverage step, no other trigger ([FR-020](spec.md#fr-020), [FR-021](spec.md#fr-021); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [plan items 3](plan.md#item-3), [4](plan.md#item-4) and [6](plan.md#item-6)).
- [X] <a id="t011"></a>T011 [[US4](spec.md#us4)] Re-run [C-06](quickstart.md#c-06) (passes), check the file parses with `ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")'`, record the result and commit [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) ([US4](spec.md#us4) scenarios 2 and 3; [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)). At `$REPO`, run `bundle exec rspec` (0 failures, random order) and `bundle exec rubocop` (no offences) and record both in the run report.

**Checkpoint**: [C-06](quickstart.md#c-06) passes. [C-07](quickstart.md#c-07) runs when the branch is pushed ([T049](#t049)).

---

<a id="phase-4"></a>
## Phase 4: User Story 1 - A reviewer with Ruby 3.4 runs the sample files with one command (Priority: P1)

**Goal**: from a clean checkout with Ruby at the version in [`.ruby-version`](../../.ruby-version), `bundle install` then [`bin/run`](../../bin/run) gives the exact sample result, from any folder ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).

**Independent Test**: [C-08](quickstart.md#c-08) to [C-12](quickstart.md#c-12). This story adds no file: its checks prove [Phase 2](#phase-2) together with `001` and `002`. A failure is a defect in the spec that owns the behaviour, fixed there test-first, then this phase is run again.

**Where it runs**: on Linux or macOS with Ruby at the version in [`.ruby-version`](../../.ruby-version). If neither is available, all of [C-09](quickstart.md#c-09) to [C-12](quickstart.md#c-12) run in one Linux container from the official `ruby:<version>` image, with the clean checkout mounted (from a Linux, macOS or WSL shell with `$CLEAN` on that shell's own filesystem; Git Bash is not used, because its POSIX temporary paths cannot be mounted by Docker Desktop): `docker run --rm -v "$CLEAN:/src" -v "$CHECKS:$CHECKS" -e CHECKS -w /src ruby:<version> bash -c 'git config --global --add safe.directory /src && <C-09: BUNDLE_FROZEN=true bundle install; then git status --porcelain, whose output must be empty and whose exit status must be 0>; <the commands of C-10 to C-12, in order>'`, where `<version>` is the text of [`.ruby-version`](../../.ruby-version) (one container, so the installed gems are kept between the commands). The scratch folder is mounted at the same path and passed in with `-e CHECKS`, and the script is in single quotes, so `$CHECKS` and `$?` are expanded by bash inside the container and not by the host shell (otherwise the redirections would fail and every `echo $?` would report the host's status); the comparisons and exit-status checks of [C-10](quickstart.md#c-10) to [C-12](quickstart.md#c-12) are unchanged. The run report says which way was used.

- [X] <a id="t012"></a>T012 [[US1](spec.md#us1)] Make the clean checkout for this phase: `git clone -c core.autocrlf=false --branch $BRANCH $SRC $CHECKS/clean` ([C-08](quickstart.md#c-08); `$BRANCH` is this implementation branch and `$SRC` is `$REPO` until the push; the final run with `$BRANCH` `main` and `$SRC` `origin` is [T050](#t050)) ([spec item 2](spec.md#item-2); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t013"></a>T013 [[US1](spec.md#us1)] Run [C-09](quickstart.md#c-09) in `$CHECKS/clean`: `BUNDLE_FROZEN=true bundle install` succeeds and `git status --porcelain` prints nothing ([US1](spec.md#us1) scenario 1; [FR-017](spec.md#fr-017); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01)).
- [X] <a id="t014"></a>T014 [[US1](spec.md#us1)] Run [C-10](quickstart.md#c-10): [`bin/run`](../../bin/run) with no arguments from the project root; standard output equals `report.txt` with `<run time>` from the file name, standard error is empty, exit status 0, and `cmp` with `final.csv` prints nothing ([US1](spec.md#us1) scenario 2; [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1), [AC-08.3](../../docs/solution-design/02-functional-requirements.md#ac-08-3); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35)).
- [X] <a id="t015"></a>T015 [[US1](spec.md#us1)] Run [C-11](quickstart.md#c-11): `../bin/run` from [`docs`](../../docs); the last line is `Output file: <project root>/output/final_balances_<run time>.csv`, the checkout's full path as `ruby -e 'puts Dir.pwd'` prints it, standard error empty, exit status 0, the file in the project's `output/` ([US1](spec.md#us1) scenario 3; [AC-08.4](../../docs/solution-design/02-functional-requirements.md#ac-08-4); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26)).
- [X] <a id="t016"></a>T016 [[US1](spec.md#us1)] Run [C-12](quickstart.md#c-12): `bundle exec rspec` (0 failures, random order, exit 0, `coverage/` written, SimpleCov's `Line coverage:` line recorded for [T038](#t038)) and `bundle exec rubocop` (no offences, exit 0) ([US1](spec.md#us1) scenario 4; [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t017"></a>T017 [[US1](spec.md#us1)] Record [C-08](quickstart.md#c-08) to [C-12](quickstart.md#c-12) in the run report, with which way they ran.

**Checkpoint**: [C-08](quickstart.md#c-08) to [C-12](quickstart.md#c-12) pass (or are left for the developer, [C-28](quickstart.md#c-28)).

---

<a id="phase-5"></a>
## Phase 5: User Story 2 - A reviewer on Windows runs `ruby bin/run` (Priority: P1)

**Goal**: on Windows, `ruby bin/run` gives exactly the Linux result, with an LF output file, even with CRLF input files ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); [page 10 pick 20](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-20)).

**Independent Test**: [C-13](quickstart.md#c-13) to [C-16](quickstart.md#c-16) and [C-43](quickstart.md#c-43) in PowerShell on Windows with RubyInstaller at the version in [`.ruby-version`](../../.ruby-version). If no such Ruby is available, they are left for the developer ([C-28](quickstart.md#c-28)). This story adds no file.

- [X] <a id="t018"></a>T018 [[US2](spec.md#us2)] Make the Windows clean checkout: (with `$env:CHECKS`, `$BRANCH`, `$SRC` and `$REPO` set as in the quickstart Prerequisites and `report.txt`, `usage.txt`, `final.csv` copied there) `git clone -c core.autocrlf=true --branch $BRANCH $SRC $env:CHECKS\win`; then `$env:BUNDLE_FROZEN='true'; bundle install` succeeds and `git status --porcelain` prints nothing ([C-13](quickstart.md#c-13) first part; [FR-017](spec.md#fr-017); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01); [plan item 15](plan.md#item-15)).
- [X] <a id="t019"></a>T019 [[US2](spec.md#us2)] Run [C-13](quickstart.md#c-13): `cmd /c "ruby bin/run > ..\wout.txt 2> ..\werr.txt"` from the project root (cmd keeps the bytes; plain PowerShell redirection would not); `$LASTEXITCODE` is 0; `wout.txt`, with CRLF changed to LF (Ruby on Windows writes console streams in text mode), equals `report.txt` with `<run time>` filled in, line by line, with `/` in `Output file: output/final_balances_<run time>.csv`; `werr.txt` is 0 bytes; the output file's bytes equal `final.csv` (LF, not CRLF) ([US2](spec.md#us2) scenario 1; [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1), [AC-08.3](../../docs/solution-design/02-functional-requirements.md#ac-08-3); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); [spec item 3](spec.md#item-3); [page 10 pick 17](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-17)).
- [X] <a id="t020"></a>T020 [[US2](spec.md#us2)] Run [C-14](quickstart.md#c-14): `cmd /c "ruby bin/run -h > ..\hout.txt 2> ..\herr.txt"`; `$LASTEXITCODE` is 1; `hout.txt` is 0 bytes; `herr.txt`, with CRLF changed to LF, equals `usage.txt` line by line ([US2](spec.md#us2) scenario 2; [AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25)).
- [X] <a id="t021"></a>T021 [[US2](spec.md#us2)] Run [C-15](quickstart.md#c-15): `cmd /c "ruby ..\bin\run > ..\..\dout.txt"` from [`docs`](../../docs); exit 0; `dout.txt`, with CRLF changed to LF, is the sample report line by line except its last line, which is `Output file: <project root>/output/final_balances_<run time>.csv`, the checkout's full path as `ruby -e 'puts Dir.pwd'` prints it (edge case "A run from another folder on Windows"; [AC-08.4](../../docs/solution-design/02-functional-requirements.md#ac-08-4); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26)).
- [X] <a id="t022"></a>T022 [[US2](spec.md#us2)] Run [C-16](quickstart.md#c-16): `git ls-files --eol data/` shows `w/crlf` for both files, so [T019](#t019) proved CRLF input gives the sample report ([US2](spec.md#us2) scenario 3; edge case "Line endings in a Windows checkout"; [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04)). Record [C-13](quickstart.md#c-13) to [C-16](quickstart.md#c-16) in the run report. At `$REPO`, run `bundle exec rspec` (0 failures, random order) and `bundle exec rubocop` (no offences) and record both in the run report.
- [X] <a id="t059"></a>T059 [[US2](spec.md#us2)] Run [C-43](quickstart.md#c-43) in the Windows clone of [T018](#t018) (`core.autocrlf=true`, after its `bundle install`): `git ls-files --eol bin/run lib` shows `i/lf` and `w/crlf`, and `bundle exec rubocop` prints `no offenses detected` with `$LASTEXITCODE` 0, [`bin/run`](../../bin/run) included, with RuboCop's default settings and without a `.gitattributes`, a `rubocop:disable` comment or any [`.rubocop.yml`](../../.rubocop.yml) change ([US2](spec.md#us2) scenario 4; [FR-018](spec.md#fr-018), [FR-025](spec.md#fr-025)(b); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [NFR-05](../../docs/solution-design/03-non-functional-requirements.md#nfr-05); [spec item 17](spec.md#item-17)). If it reports `Layout/EndOfLine: Carriage return character missing` for any file, a file was forced to LF: remove the cause, never the cop. Record [C-43](quickstart.md#c-43) in the run report.

**Checkpoint**: [C-13](quickstart.md#c-13) to [C-16](quickstart.md#c-16) and [C-43](quickstart.md#c-43) pass (or are left for the developer, [C-28](quickstart.md#c-28)).

---

<a id="phase-6"></a>
## Phase 6: User Story 3 - A reviewer without Ruby 3.4 uses Docker (Priority: P2)

**Goal**: the image `mable-transfers` builds from a clean checkout, runs the sample files with `output` mounted and `TZ` set, runs the tests, and passes the streams and the exit status through ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).

**Independent Test**: [C-04](quickstart.md#c-04), [C-42](quickstart.md#c-42) and [C-17](quickstart.md#c-17) to [C-27](quickstart.md#c-27) with Docker. Run them from a Linux, macOS or WSL shell, not Git Bash ([plan item 17](plan.md#item-17)); [C-19](quickstart.md#c-19) creates `output/` with `mkdir -p` first ([plan item 18](plan.md#item-18)). If Docker is not available, they are left for the developer ([C-28](quickstart.md#c-28)).

### Checks first

- [X] <a id="t023"></a>T023 [[US3](spec.md#us3)] Run [C-04](quickstart.md#c-04), [C-17](quickstart.md#c-17) and [C-42](quickstart.md#c-42) at `$REPO` and record that all three fail: there is no [`Dockerfile`](../../Dockerfile) ([FR-015](spec.md#fr-015), [FR-022](spec.md#fr-022), [FR-024](spec.md#fr-024)).

### Implementation

- [X] <a id="t024"></a>T024 [[US3](spec.md#us3)] Create [`Dockerfile`](../../Dockerfile) at the repository root with exactly the six instructions of [contracts/dockerfile.md](contracts/dockerfile.md), in order: `FROM ruby:<the text of .ruby-version>`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN sed -i 's/\r$//' bin/run && bundle install` (strips the carriage returns from [`bin/run`](../../bin/run) in the image, so Ruby writes no shebang warning; [spec item 18](spec.md#item-18)), `CMD ["ruby", "bin/run"]` (exec form, so an image built from a Windows checkout starts); no `apt-get`, `USER`, `ENTRYPOINT` or other instruction, and no `.dockerignore` ([FR-022](spec.md#fr-022), [FR-023](spec.md#fr-023), [FR-024](spec.md#fr-024); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); spec [Clarifications](spec.md#clarifications); [plan items 1](plan.md#item-1), [5](plan.md#item-5) and [6](plan.md#item-6)).
- [X] <a id="t025"></a>T025 [[US3](spec.md#us3)] Re-run [C-04](quickstart.md#c-04) and [C-42](quickstart.md#c-42) (both pass: six instructions, none of `USER`, `ENTRYPOINT`, `EXPOSE`, `ADD`, `apt-get` or `gem install`, no `.dockerignore`), commit [`Dockerfile`](../../Dockerfile), and make a fresh clean checkout of the branch in `$CHECKS/docker` (as [T012](#t012)), so the image is built only from committed files.

### Checks on the built image (in `$CHECKS/docker`)

- [X] <a id="t026"></a>T026 [[US3](spec.md#us3)] Run [C-17](quickstart.md#c-17): `docker build -t mable-transfers .` exits 0 and the frozen `bundle install` in it succeeds ([US3](spec.md#us3) scenario 1; [FR-017](spec.md#fr-017), [FR-022](spec.md#fr-022); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t027"></a>T027 [[US3](spec.md#us3)] Run [C-18](quickstart.md#c-18): `/usr/share/zoneinfo/Australia/Sydney` exists in the image. If it does not, change the first line of [`Dockerfile`](../../Dockerfile) to `FROM ruby:<version>-bookworm`, commit, and repeat [T025](#t025) to T027 ([FR-022](spec.md#fr-022), [FR-024](spec.md#fr-024); [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); [plan item 7](plan.md#item-7)).
- [X] <a id="t028"></a>T028 [[US3](spec.md#us3)] Run [C-19](quickstart.md#c-19): the POSIX run command of [contracts/dockerfile.md](contracts/dockerfile.md#commands-the-readme-gives) with `TZ=Australia/Sydney` and `output` mounted; exit 0; standard output equals the sample report with `<run time>` in Sydney time; standard error empty; the file in the host's `output/` equals `final.csv` ([US3](spec.md#us3) scenario 2; [FR-023](spec.md#fr-023); [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- [X] <a id="t029"></a>T029 [[US3](spec.md#us3)] Run [C-20](quickstart.md#c-20): `docker run --rm mable-transfers bundle exec rspec`; 0 failures, random order, exit 0 ([US3](spec.md#us3) scenario 3; [FR-023](spec.md#fr-023); [DEC-34](../../docs/design-analysis/design-decisions.md#dec-34), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t030"></a>T030 [[US3](spec.md#us3)] Run [C-21](quickstart.md#c-21): with `-e LOG_LEVEL=info`, exit 0, the report on standard output (`<run time>` taken from its last line, as no output file is left on the host) and the six [AC-09.5](../../docs/solution-design/02-functional-requirements.md#ac-09-5) lines on standard error (timestamps and pid aside); with the command `ruby bin/run -h`, exit 1, standard output empty, standard error equal to `usage.txt` ([US3](spec.md#us3) scenario 4; [AC-09.5](../../docs/solution-design/02-functional-requirements.md#ac-09-5), [AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2); [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28)).
- [X] <a id="t031"></a>T031 [[US3](spec.md#us3)] Run [C-22](quickstart.md#c-22): no `TZ`; exit 0; the file name carries the UTC time (edge case "Docker with no TZ"; [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- [X] <a id="t032"></a>T032 [[US3](spec.md#us3)] Run [C-23](quickstart.md#c-23): no mount; exit 0; the report on standard output (`<run time>` taken from its last line); no `output/` on the host (edge case "Docker with no output mount"; [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- [X] <a id="t033"></a>T033 [[US3](spec.md#us3)] Run [C-24](quickstart.md#c-24): a typed output path that already exists in the mounted `output/`; standard output empty; standard error `Error: output file already exists: output/existing.csv. Delete it or give another output path.` then `E, [<timestamp> #<pid>] ERROR -- : Run stopped: start checks failed (output file already exists)`; exit 1; the file still holds `keep` (edge case "Docker with a mount and an existing file of the same name"; [AC-09.3](../../docs/solution-design/02-functional-requirements.md#ac-09-3); [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27)).
- [X] <a id="t034"></a>T034 [[US3](spec.md#us3)] Run [C-25](quickstart.md#c-25): copies of the sample files in a mounted scratch folder, passed as typed paths; exit 0; the sample report; the copies stay in `$CHECKS`, never committed (edge case "Docker with typed paths"; [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); [spec item 6](spec.md#item-6)).
- [X] <a id="t035"></a>T035 [[US3](spec.md#us3)] Run [C-26](quickstart.md#c-26): in a fresh Windows checkout made with `core.autocrlf=true` (as [T018](#t018), with `$BRANCH`, `$SRC` and `$env:CHECKS` set, after [T025](#t025), into `$env:CHECKS\win2`, with no `output/` folder; the same clone as the quickstart's [C-26](quickstart.md#c-26) and [C-41](quickstart.md#c-41)), `git ls-files --eol bin/run` shows `i/lf` and `w/crlf`; build `mable-transfers-win`, run it with no command (exit 0, the sample report with `<run time>` taken from its last line, nothing on standard error) and with the command `bundle exec rspec` (exit 0, `0 failures`; [spec item 18](spec.md#item-18)), then remove that image; then run `docker build -t mable-transfers .` in the same clone and [C-41](quickstart.md#c-41), the README's PowerShell Docker command as written (exit 0, the sample report on standard output, nothing on standard error, the sample file in `output/`) (edge case "[`bin/run`](../../bin/run) on Linux and macOS (and `ruby bin/run` in Docker)"; [FR-018](spec.md#fr-018), [FR-022](spec.md#fr-022); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22); spec [Clarifications](spec.md#clarifications) and [item 17](spec.md#item-17)).
- [X] <a id="t036"></a>T036 [[US3](spec.md#us3)] Run [C-27](quickstart.md#c-27) on a Linux host if one is available (the file in `output/` belongs to root); on Docker Desktop record the owner seen instead (edge case "Docker on a Linux host"; [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)). Record [C-17](quickstart.md#c-17) to [C-27](quickstart.md#c-27) in the run report. At `$REPO`, run `bundle exec rspec` (0 failures, random order) and `bundle exec rubocop` (no offences) and record both in the run report.

**Checkpoint**: [C-04](quickstart.md#c-04), [C-42](quickstart.md#c-42) and [C-17](quickstart.md#c-17) to [C-26](quickstart.md#c-26) pass ([C-27](quickstart.md#c-27) recorded), or are left for the developer ([C-28](quickstart.md#c-28)); the suite and RuboCop still pass.

---

<a id="phase-7"></a>
## Phase 7: User Story 5 - A reviewer finds everything they need in the README (Priority: P1)

**Goal**: [`README.md`](../../README.md) holds every item of [FR-001](spec.md#fr-001) to [FR-014](spec.md#fr-014), in the order of [contracts/readme.md](contracts/readme.md), with every command proved by [Phases 4](#phase-4) to [6](#phase-6) and every exact text copied from [page 2](../../docs/solution-design/02-functional-requirements.md) ([DEC-37](../../docs/design-analysis/design-decisions.md#dec-37), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04)).

**Independent Test**: [C-29](quickstart.md#c-29) to [C-33](quickstart.md#c-33).

### Checks first

- [X] <a id="t037"></a>T037 [[US5](spec.md#us5)] Run [C-31](quickstart.md#c-31), the README check [R-01](contracts/readme.md#r-01) to [R-14](contracts/readme.md#r-14) of [contracts/readme.md](contracts/readme.md#the-readme-check-c-31), against the current [`README.md`](../../README.md) and record each failing item (all of [R-01](contracts/readme.md#r-01) to [R-14](contracts/readme.md#r-14) fail: the README is still the design-analysis placeholder, with its "Status" and "To be added" sections) ([FR-001](spec.md#fr-001) to [FR-014](spec.md#fr-014); [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- [X] <a id="t038"></a>T038 [[US5](spec.md#us5)] Take the coverage figure: SimpleCov's `Line coverage: <covered> / <total> (<percent>%)` line from the full `bundle exec rspec` run on the clean checkout of the final code ([T016](#t016) or [T029](#t029); both must print the same line) ([FR-012](spec.md#fr-012); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [plan item 10](plan.md#item-10)).

### Implementation (one file, so in order)

- [X] <a id="t039"></a>T039 [[US5](spec.md#us5)] In [`README.md`](../../README.md), write the title, the two-sentence summary and section 1 `## Build, test and run` with `### With Ruby 3.4`, `### On Windows` and `### With Docker` as [contracts/readme.md](contracts/readme.md#2--build-test-and-run-fr-001-to-fr-005): the commands, the [AC-09.1](../../docs/solution-design/02-functional-requirements.md#ac-09-1) table, the path rules, the default output name and no overwrite, the usage message copied from [AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2), the sample report copied from [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1) with `2026-11-07_143005`, `ruby bin/run` on Windows, the four Docker commands of [contracts/dockerfile.md](contracts/dockerfile.md#commands-the-readme-gives) and the four Docker lines (UTC unless `TZ`; the mount keeps the CSV; own files mounted; root on a Linux host), with no `--user` ([FR-001](spec.md#fr-001) to [FR-005](spec.md#fr-005); [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37); [spec items 5](spec.md#item-5), [6](spec.md#item-6) and [8](spec.md#item-8)).
- [X] <a id="t040"></a>T040 [[US5](spec.md#us5)] Write `## Input files` and `## Log level and exit status`: both formats, no header, a header row is a bad row; `LOG_LEVEL` `warn` (default) or `info` in any letter case, any other value `warn`; log lines on standard error masked as `************6789`; the report alone on standard output; exit 0 and exit 1 with the eight [AC-09.8](../../docs/solution-design/02-functional-requirements.md#ac-09-8) reasons ([FR-006](spec.md#fr-006), [FR-007](spec.md#fr-007), [FR-008](spec.md#fr-008); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-06](../../docs/design-analysis/design-decisions.md#dec-06), [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-28](../../docs/design-analysis/design-decisions.md#dec-28), [DEC-29](../../docs/design-analysis/design-decisions.md#dec-29)).
- [X] <a id="t041"></a>T041 [[US5](spec.md#us5)] Write `## Assumptions`: the ten rows of [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) Assumptions with their reasons, worded as there, links rewritten to `docs/design-analysis/design-decisions.md#dec-nn` ([FR-009](spec.md#fr-009); [spec item 10](spec.md#item-10)).
- [X] <a id="t042"></a>T042 [[US5](spec.md#us5)] Write `## Design`: light domain-driven design with the rules in the models, the folders [`lib/domain`](../../lib/domain), [`lib/application`](../../lib/application) and [`lib/infrastructure`](../../lib/infrastructure), the in-memory `AccountRepository` (`add`, `include?`, `find`, `all`), the parts passed in to `ProcessDailyTransfer`, every check before any balance changes, `Money` on `BigDecimal`; links to [`docs/design-analysis/design-decisions.md`](../../docs/design-analysis/design-decisions.md) and [`docs/solution-design/README.md`](../../docs/solution-design/README.md) ([FR-010](spec.md#fr-010); [DEC-30](../../docs/design-analysis/design-decisions.md#dec-30), [DEC-31](../../docs/design-analysis/design-decisions.md#dec-31), [DEC-18](../../docs/design-analysis/design-decisions.md#dec-18), [DEC-09](../../docs/design-analysis/design-decisions.md#dec-09)).
- [X] <a id="t043"></a>T043 [[US5](spec.md#us5)] Write `## Test coverage`: the line from [T038](#t038), that the full report is in `coverage/index.html` after a test run, and that no minimum is set ([FR-012](spec.md#fr-012); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t044"></a>T044 [[US5](spec.md#us5)] Write `## Storage, production and known limitations`: (a) what a version with storage would need to stay safe to rerun, and that remembering applied files across runs is out of scope; (b) very large files (streaming or chunking), a database repository with database transactions or sagas; (c) the nine known limitations of [contracts/readme.md](contracts/readme.md#9--storage-production-and-known-limitations-fr-011-dec-03-dec-18-dec-32), one line each ([FR-011](spec.md#fr-011); [DEC-03](../../docs/design-analysis/design-decisions.md#dec-03), [DEC-18](../../docs/design-analysis/design-decisions.md#dec-18), [DEC-32](../../docs/design-analysis/design-decisions.md#dec-32); [page 9](../../docs/solution-design/09-considerations.md) risks; [page 10](../../docs/solution-design/10-traceability-glossary-assumptions.md); [spec item 11](spec.md#item-11)).
- [X] <a id="t045"></a>T045 [[US5](spec.md#us5)] Write `## How this was built`: made with an AI assistant, the four steps (design analysis, solution design, GitHub Spec Kit specification, test-first implementation through the Spec Kit tasks) with links to [`docs/design-analysis/design-decisions.md`](../../docs/design-analysis/design-decisions.md), [`docs/solution-design/README.md`](../../docs/solution-design/README.md), [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) and [`specs/`](../), and the prompt logs in [`docs/prompts/`](../../docs/prompts/) ([FR-013](spec.md#fr-013); CLAUDE.md "Prompt log"; [spec item 12](spec.md#item-12)).
- [X] <a id="t046"></a>T046 [[US5](spec.md#us5)] Write `## Repository layout` (the table of [contracts/readme.md](contracts/readme.md#11--repository-layout-fr-014)) and `## The challenge` (the link to [`docs/challenge/MABLE_BACK_END_CODE_TEST.md`](../../docs/challenge/MABLE_BACK_END_CODE_TEST.md)); remove the "Status" section, the Google Sheet link and every "To be added"; name no company whose balances are processed ([FR-014](spec.md#fr-014); [DEC-02](../../docs/design-analysis/design-decisions.md#dec-02), [DEC-38](../../docs/design-analysis/design-decisions.md#dec-38); [plan items 11](plan.md#item-11) and [16](plan.md#item-16)).

### Checks again

- [X] <a id="t047"></a>T047 [[US5](spec.md#us5)] Run [C-41](quickstart.md#c-41) if not already run in [T035](#t035) (the README's PowerShell Docker command as written, or recorded under [C-28](quickstart.md#c-28) as left for the developer), then [C-29](quickstart.md#c-29) (each README command equals one proved in [T013](#t013) to [T036](#t036) or [C-41](quickstart.md#c-41), plain `bundle install` as the README gives it is run once on a fresh clean checkout with exit 0 and `git status --porcelain` empty, and both `bin/run b.csv t.csv` and `bin/run b.csv t.csv out/day1.csv` run once on the clean checkout with copies of the sample files), [C-30](quickstart.md#c-30) (`diff` of the README's report and usage blocks with [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1) and [AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2) prints nothing), [C-31](quickstart.md#c-31) (14 of 14, in order), [C-32](quickstart.md#c-32) (every relative link resolves) and the local part of [C-33](quickstart.md#c-33) (the README's line equals [T038](#t038)); record them and commit [`README.md`](../../README.md) ([US5](spec.md#us5) scenarios 1 to 5; [SC-003](spec.md#sc-003), [SC-004](spec.md#sc-004); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)). At `$REPO`, run `bundle exec rspec` (0 failures, random order) and `bundle exec rubocop` (no offences) and record both in the run report.

**Checkpoint**: [C-29](quickstart.md#c-29) to [C-32](quickstart.md#c-32) pass and the README's figure equals [T038](#t038); the suite and RuboCop still pass.

---

<a id="phase-8"></a>
## Phase 8: Push, CI and User Story 6 - The submission holds everything needed and nothing generated (Priority: P2)

**Goal**: CI is green on the pushed branch and on `main`; every hand check is repeated from a clean checkout of `origin` `main`; the repository holds what it must and nothing generated; making it public is left to the developer ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04)).

**Independent Test**: [C-07](quickstart.md#c-07), [C-34](quickstart.md#c-34) to [C-39](quickstart.md#c-39), and [C-08](quickstart.md#c-08) to [C-27](quickstart.md#c-27), [C-29](quickstart.md#c-29), [C-33](quickstart.md#c-33), [C-41](quickstart.md#c-41), [C-42](quickstart.md#c-42) and [C-43](quickstart.md#c-43) again on `main`.

- [X] <a id="t048"></a>T048 Run [C-34](quickstart.md#c-34) on this branch against the tip of `002-file-runner`'s implementation: `git diff --stat <002 tip> HEAD -- lib spec data` prints nothing ([FR-030](spec.md#fr-030), [SC-007](spec.md#sc-007); [brief rule 4](../../docs/spec-kit/spec-kit-brief.md#4-how-the-tests-are-split)).
- [X] <a id="t049"></a>T049 [[US4](spec.md#us4)] After the review loop finds 0 defects and the branch is pushed ([brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) step 2), run [C-07](quickstart.md#c-07) on the pushed head commit: one run, conclusion `success`, a frozen install, `0 failures`, `no offenses detected` ([US4](spec.md#us4) scenario 1; [FR-020](spec.md#fr-020), [SC-002](spec.md#sc-002); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)). A failure is fixed on the branch, test-first, and pushed again.
- [X] <a id="t050"></a>T050 [[US6](spec.md#us6)] After the implementation branches are merged and `main` is pushed ([brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) step 4), make fresh clean checkouts of `origin` `main` and repeat [C-08](quickstart.md#c-08) to [C-12](quickstart.md#c-12) (as [Phase 4](#phase-4)), [C-13](quickstart.md#c-13) to [C-16](quickstart.md#c-16) and [C-43](quickstart.md#c-43) (as [Phase 5](#phase-5); [C-43](quickstart.md#c-43) is `bundle exec rubocop` in the fresh `core.autocrlf=true` clone, expecting `no offenses detected` and exit 0) and [C-17](quickstart.md#c-17) to [C-27](quickstart.md#c-27) and [C-42](quickstart.md#c-42) (as [Phase 6](#phase-6), in their own fresh clean checkout of `origin` `main`, as [T025](#t025) does, not the checkout of [C-08](quickstart.md#c-08)) on them, [C-29](quickstart.md#c-29) (as [T047](#t047), on a fresh clean checkout with copies of the sample files) and [C-41](quickstart.md#c-41) (as [T035](#t035), in a fresh `core.autocrlf=true` Windows clone of `origin` `main`; recorded under [C-28](quickstart.md#c-28) if it cannot run), and [C-33](quickstart.md#c-33) against the CI log of the latest `main` commit. If the coverage line differs from the README's (the code changed after [T038](#t038)), update `## Test coverage` in [`README.md`](../../README.md) and commit it on the implementation branch (or a branch from `main`), have a separate review agent that did not write or fix the change approve it, then push `main` ([brief rule 5](../../docs/spec-kit/spec-kit-brief.md#5-rules); Part 2 step 4), and repeat [C-33](quickstart.md#c-33) ([FR-025](spec.md#fr-025), [FR-012](spec.md#fr-012); [SC-001](spec.md#sc-001), [SC-004](spec.md#sc-004); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- [X] <a id="t051"></a>T051 [P] [[US6](spec.md#us6)] Run [C-35](quickstart.md#c-35) on `main`: `git ls-files` lists every path of [repository-files.md](contracts/repository-files.md#the-pushed-main-must-be-tracked-git-ls-files) ([US6](spec.md#us6) scenario 1; [FR-026](spec.md#fr-026); [DEC-38](../../docs/design-analysis/design-decisions.md#dec-38), [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01)).
- [X] <a id="t052"></a>T052 [P] [[US6](spec.md#us6)] Run [C-36](quickstart.md#c-36) on `main`: `git ls-files output coverage` prints nothing, and `git status --porcelain` on the clean checkout after a run and a test run prints nothing ([US6](spec.md#us6) scenario 2; [FR-027](spec.md#fr-027), [SC-006](spec.md#sc-006); [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t053"></a>T053 [P] [[US6](spec.md#us6)] Run [C-37](quickstart.md#c-37) on `main`: [`docs/challenge/`](../../docs/challenge/) has no difference from the commit that added it, and the blob IDs of the copies in [`data/`](../../data/) and [`spec/fixtures/sample/`](../../spec/fixtures/sample/) equal the challenge files' ([US6](spec.md#us6) scenario 3; [FR-028](spec.md#fr-028), [SC-006](spec.md#sc-006); [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)).
- [X] <a id="t054"></a>T054 [[US6](spec.md#us6)] Run [C-38](quickstart.md#c-38): the latest `main` commit's GitHub Actions run has conclusion `success` ([US6](spec.md#us6) scenario 4; [FR-029](spec.md#fr-029), [SC-002](spec.md#sc-002); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- [X] <a id="t055"></a>T055 [[US6](spec.md#us6)] Run [C-39](quickstart.md#c-39) and [C-28](quickstart.md#c-28): the run report's "left for the developer" list names making the repository public or sharing it with the reviewer at submission time, and every hand check that could not be run, with its reason ([US6](spec.md#us6) scenario 4; [FR-025](spec.md#fr-025), [FR-029](spec.md#fr-029); [DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)).

**Checkpoint**: [C-07](quickstart.md#c-07) and [C-34](quickstart.md#c-34) to [C-39](quickstart.md#c-39) pass; every [C-08](quickstart.md#c-08) to [C-27](quickstart.md#c-27), [C-29](quickstart.md#c-29), [C-41](quickstart.md#c-41), [C-42](quickstart.md#c-42) and [C-43](quickstart.md#c-43) result on `main` is recorded as passed or left for the developer.

---

<a id="phase-9"></a>
## Phase 9: Polish and cross-cutting checks

- [X] <a id="t056"></a>T056 Record the success criteria in the run report from the results above: [SC-001](spec.md#sc-001) (3 of 3 platforms, or which are left for the developer), [SC-002](spec.md#sc-002), [SC-003](spec.md#sc-003) (14 of 14), [SC-004](spec.md#sc-004), [SC-005](spec.md#sc-005), [SC-006](spec.md#sc-006) and [SC-007](spec.md#sc-007) (spec Success Criteria).
- [X] <a id="t057"></a>T057 Run [C-40](quickstart.md#c-40), the design review of how the input files are read: `grep -rn -e 'File.read' -e 'IO.read' -e 'readlines' -e 'each_line' lib/` finds no reading of an input file, and the readers in [`lib/infrastructure`](../../lib/infrastructure) open the files as `bom|utf-8` through Ruby's CSV library (`002` [FR-001](../002-file-runner/spec.md#fr-001)); record the result in the run report ([FR-019](spec.md#fr-019); [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)).
- [X] <a id="t058"></a>T058 On the final `main` commit, confirm `bundle exec rspec` passes in random order and `bundle exec rubocop` reports no offences, and that no file under [`lib/`](../../lib/), [`bin/`](../../bin/) (other than [`bin/run`](../../bin/run)'s mode, its first line and, only if RuboCop needs it, the `# frozen_string_literal: true` comment on line 2, [spec item 16](spec.md#item-16)), [`spec/`](../../spec/) or [`data/`](../../data/) was changed by this spec ([FR-030](spec.md#fr-030); [constitution III](../../.specify/memory/constitution.md#iii-short-readable-methods) and [IV](../../.specify/memory/constitution.md#iv-tests-first-non-negotiable)).

---

<a id="phase-10"></a>
## Phase 10: The documents say what the README holds (review of the documents)

**Goal**: this spec's documents list the README's sections and its "How this was built" steps as the README has them, and count the spec's own items correctly; the README does not change.

**Independent Test**: the lists below, read against the headings of [`README.md`](../../README.md); every relative link and anchor in the changed pages resolves.

- [X] <a id="t060"></a>T060 [P] List the README's sections as its headings are, `Prerequisites` first and `Troubleshooting` after `Log level and exit status` ([DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)), in the [README contract](contracts/readme.md) ([R-01](contracts/readme.md#r-01)), [FR-001](spec.md#fr-001), [clarification 5](spec.md#clarification-5) and [plan item 9](plan.md#item-9); give "How this was built" its six steps, the first four with links, in the contract ([R-13](contracts/readme.md#r-13)), [FR-013](spec.md#fr-013) and [item 12](spec.md#item-12); update the three links in this file to the renumbered contract sections [[FR-001](spec.md#fr-001), [FR-013](spec.md#fr-013); [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)]
- [X] <a id="t061"></a>T061 [P] Count the spec's "Decided in the run" items as 18 in the plan, the research and the [requirements checklist](checklists/requirements.md) [[DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)]

- [X] <a id="t062"></a>T062 [P] Keep "no `.gitattributes`" and say why RuboCop reports no offence in a Windows checkout or a download with LF files: [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36) turns `Layout/EndOfLine` off (`001` [T081](../001-domain/tasks.md#t081)), not RuboCop's `native` style; in [clarification 2](spec.md#clarification-2), [US2](spec.md#us2) scenario 4, [FR-018](spec.md#fr-018), [item 17](spec.md#item-17), [plan item 19](plan.md#item-19), research [R-3](research.md#r-3) and the [repository files contract](contracts/repository-files.md); the completed [T005](#t005) and [T059](#t059) stay as run [[FR-018](spec.md#fr-018); [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)]

**Checkpoint**: the documents list what the README holds; every link resolves.

---

## Edge cases and their checks

Every edge case in the spec, and every decision edge case within this spec's scope, has a planned check.

| Edge case | Check | Task | DEC |
|---|---|---|---|
| Docker with no `TZ` | [C-22](quickstart.md#c-22) | [T031](#t031) | [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) |
| Docker with no `output` mount | [C-23](quickstart.md#c-23) | [T032](#t032) | [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) |
| Docker with a mount and an existing file of the same name | [C-24](quickstart.md#c-24) | [T033](#t033) | [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25), [DEC-27](../../docs/design-analysis/design-decisions.md#dec-27) |
| Docker with typed paths | [C-25](quickstart.md#c-25) | [T034](#t034) | [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22) |
| A lock file made on Windows | [C-03](quickstart.md#c-03), [C-09](quickstart.md#c-09), [C-13](quickstart.md#c-13), [C-17](quickstart.md#c-17), [C-07](quickstart.md#c-07) | [T007](#t007), [T013](#t013), [T018](#t018), [T026](#t026), [T049](#t049) | [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01) |
| [`bin/run`](../../bin/run) on Linux and macOS (and `ruby bin/run` in Docker) | [C-01](quickstart.md#c-01), [C-10](quickstart.md#c-10), [C-19](quickstart.md#c-19), [C-26](quickstart.md#c-26) | [T006](#t006), [T014](#t014), [T028](#t028), [T035](#t035) | [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22) |
| Line endings in a Windows checkout | [C-16](quickstart.md#c-16), [C-26](quickstart.md#c-26), [C-43](quickstart.md#c-43) | [T022](#t022), [T035](#t035), [T059](#t059) | [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36) |
| Input files read only through the CSV library (CRLF, no final newline, BOM) | [C-40](quickstart.md#c-40) | [T057](#t057) | [DEC-04](../../docs/design-analysis/design-decisions.md#dec-04), [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22) |
| Docker on a Linux host | [C-27](quickstart.md#c-27) | [T036](#t036) | [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) |
| A Windows reviewer with Docker Desktop (PowerShell command) | [C-41](quickstart.md#c-41), [C-29](quickstart.md#c-29) | [T035](#t035), [T047](#t047) | [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) |
| A run from another folder on Windows | [C-15](quickstart.md#c-15) | [T021](#t021) | [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26) |
| No Ruby 3.4 on the Windows machine, or no Docker | [C-28](quickstart.md#c-28) | [T055](#t055) | [brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) step 3 |
| A newer Ruby 3.4.x released after [`.ruby-version`](../../.ruby-version) is set | [C-04](quickstart.md#c-04) | [T002](#t002), [T025](#t025) | [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01) |
| From any folder (Linux or macOS) | [C-11](quickstart.md#c-11) | [T015](#t015) | [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-26](../../docs/design-analysis/design-decisions.md#dec-26) |
| `-h` gives the usage message and exit 1 | [C-14](quickstart.md#c-14), [C-21](quickstart.md#c-21) | [T020](#t020), [T030](#t030) | [DEC-22](../../docs/design-analysis/design-decisions.md#dec-22), [DEC-25](../../docs/design-analysis/design-decisions.md#dec-25) |
| Exactly the [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35) closing balances on every platform | [C-10](quickstart.md#c-10), [C-13](quickstart.md#c-13), [C-19](quickstart.md#c-19) | [T014](#t014), [T019](#t019), [T028](#t028) | [DEC-35](../../docs/design-analysis/design-decisions.md#dec-35) |

---

## Dependencies and execution order

### Phase dependencies

- **[Phase 1](#phase-1) (Setup)**: none; starts once `001` and `002` are implemented.
- **[Phase 2](#phase-2) (Foundational)**: after [Phase 1](#phase-1); blocks every story ([`bin/run`](../../bin/run)'s storage and the lock platforms are needed by CI, Windows and Docker).
- **[Phase 3](#phase-3) ([US4](spec.md#us4))**: after [Phase 2](#phase-2).
- **[Phase 4](#phase-4) ([US1](spec.md#us1))** and **[Phase 5](#phase-5) ([US2](spec.md#us2))**: after [Phase 2](#phase-2); independent of each other and of [US4](spec.md#us4).
- **[Phase 6](#phase-6) ([US3](spec.md#us3))**: after [Phase 2](#phase-2); [T035](#t035) reuses the Windows clone method of [Phase 5](#phase-5).
- **[Phase 7](#phase-7) ([US5](spec.md#us5))**: after [Phases 4](#phase-4) to [6](#phase-6), because the README gives only commands those phases proved, and the coverage figure comes from [T016](#t016) or [T029](#t029).
- **[Phase 8](#phase-8) ([US6](spec.md#us6) and [C-07](quickstart.md#c-07))**: after [Phase 7](#phase-7), the review loop and the pushes in [brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) steps 2 and 4.
- **[Phase 9](#phase-9) (Polish)**: last of the delivery phases.
- **[Phase 10](#phase-10) (Documents)**: after [Phase 9](#phase-9); the README is unchanged.

### User story dependencies

- [US1](spec.md#us1), [US2](spec.md#us2), [US3](spec.md#us3) and [US4](spec.md#us4) depend only on [Phase 2](#phase-2).
- [US5](spec.md#us5) depends on [US1](spec.md#us1), [US2](spec.md#us2) and [US3](spec.md#us3) (proved commands) and on the coverage figure.
- [US6](spec.md#us6) depends on all the others and on the push of `main`.

### Within each phase

- The check is run before the file it checks is created or changed, and seen to fail.
- One file at a time: every README task edits [`README.md`](../../README.md), so [T039](#t039) to [T046](#t046) run in order.
- Each phase ends with its checks passing, the suite passing in random order and RuboCop reporting no offences.

## Parallel opportunities

- [T003](#t003) can run while [T001](#t001) and [T002](#t002) run.
- Once [Phase 2](#phase-2) is done, [Phase 3](#phase-3) (CI file), [Phase 4](#phase-4) (Linux or macOS), [Phase 5](#phase-5) (Windows) and [Phase 6](#phase-6) (Docker) can run on different machines at the same time.
- [T051](#t051), [T052](#t052) and [T053](#t053) read different things and can run together.

```text
# After Phase 2, on three machines at once:
Machine A (Linux or macOS): T012 to T017 (US1)
Machine B (Windows):        T018 to T022 and T059 (US2)
Machine C (Docker host):    T023 to T036 (US3)
```

## Implementation strategy

### First increment

1. [Phases 1](#phase-1) and [2](#phase-2): the repository files.
2. [Phase 3](#phase-3): the CI workflow, so every later push is checked.
3. [Phase 4](#phase-4): the normal way to run, proved from a clean checkout. **Stop and check** [C-08](quickstart.md#c-08) to [C-12](quickstart.md#c-12).

### Then

4. [Phase 5](#phase-5) (Windows) and [Phase 6](#phase-6) (Docker), each proved from a clean checkout.
5. [Phase 7](#phase-7): the README, written from the proved commands and the coverage figure.
6. [Phase 8](#phase-8): push, CI, the repeat on `main` and the submission check; [Phase 9](#phase-9).

## Notes

- No RSpec spec, class, message or test-data file is added ([FR-030](spec.md#fr-030)). A defect found by a check in another spec's behaviour is fixed in that spec, test-first, not worked around here.
- Scratch files (`$CHECKS`, the copies in [C-25](quickstart.md#c-25)) stay outside the repository and are never committed.
- Nothing is pushed except as [brief Part 2](../../docs/spec-kit/spec-kit-brief.md#part-2-implementation) says; making the repository public is the developer's step ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)).
