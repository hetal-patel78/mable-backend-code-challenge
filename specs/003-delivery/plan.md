# Implementation Plan: Delivery: README, CI, Docker and the submission

**Branch**: `003-delivery` | **Date**: 2026-11-08 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-delivery/spec.md`

**Sources, in order of precedence**: [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) (DEC-01 to DEC-38), the [solution design](../../docs/solution-design/README.md) (pages 01, 02, 03, 04, 05, 09 and 10), `CLAUDE.md`, the [constitution](../../.specify/memory/constitution.md), then [spec.md](spec.md). If this plan ever differs from them, they win.

## Summary

This spec owns [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04) Language version and portability, and delivers what a reviewer needs around the finished program built by `001-domain` and `002-file-runner`: the README ([DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)) with the coverage figure ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)), a GitHub Actions workflow running RSpec and RuboCop on every push, a Dockerfile as the fallback way to run, a one-line `.gitattributes`, the `Gemfile.lock` platforms, and the checks that prove them: CI, a Docker run, a Windows run and a Linux or macOS run from a clean checkout, the README check and the submission check ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)).

It changes no behaviour of the program and adds no class, no message, no RSpec spec and no test-data file (FR-030, brief rule 4). Its "tests" are the checks in [quickstart.md](quickstart.md): each is written before the file it checks, seen to fail, and passes once the file is in place.

## Technical Context

**Language/Version**: Ruby, the latest 3.4.x release, exactly the version in `.ruby-version` (set by `001-domain`, FR-036 there; [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01)). This spec repeats that version in one place only, the Dockerfile's base image (FR-015).

**Primary Dependencies**: none added. Runtime gems `csv`, `bigdecimal` and `logger`; development gems `rspec`, `simplecov`, `rubocop` and `rubocop-rspec`, all set by `001-domain` (FR-037 there). Bundler, with `Gemfile.lock` committed. Outside the program: GitHub Actions with the actions `actions/checkout` and `ruby/setup-ruby`, and the official Ruby Docker image ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)). No other gem, framework, tool or library.

**Storage**: N/A. Files only: the README, the workflow file, the Dockerfile, `.gitattributes` and the platform list in `Gemfile.lock`.

**Testing**: no new RSpec spec (FR-030). The existing suite (RSpec in random order, with SimpleCov) and RuboCop with `rubocop-rspec` run in CI, in Docker and on each clean checkout. This spec's own checks are the commands C-01 to C-41 in [quickstart.md](quickstart.md), run by hand or by the implementing agent, with each result recorded in the run report (`docs/spec-kit/implementation-run-report.md`).

**Target Platform**: Linux and macOS (`bin/run`), Windows (`ruby bin/run`), Docker (Linux containers, on an x86-64 or ARM64 host), and the latest Ubuntu runner on GitHub Actions ([NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04); page 10 picks 20 and 50).

**Project Type**: command-line program (single project); this spec adds delivery files around it.

**Performance Goals**: none. NFR-02 and NFR-03 are owned elsewhere and checked by design review.

**Constraints**: one Ruby version, written in `.ruby-version` and the Dockerfile only; `Gemfile.lock` installs unchanged, frozen, on Windows, the CI runner and the Docker image; no coverage minimum, no CI matrix, no Ruby version in the workflow; nothing added to the Dockerfile beyond [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); no `.dockerignore`; every text file stored with LF; nothing out of scope on [page 4](../../docs/solution-design/04-scope.md).

**Scale/Scope**: 5 files created or changed (`README.md`, `.github/workflows/ci.yml`, `Dockerfile`, `.gitattributes`, `Gemfile.lock`), 41 checks, 6 user stories.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle ([constitution](../../.specify/memory/constitution.md)) | How this plan meets it | Result |
|---|---|---|
| I. Domain models encapsulate their own rules | No model is added or changed (FR-030). The README explains the models' rules ([DEC-30](../../docs/design-analysis/design-decisions.md#dec-30)) without restating them in code. | Pass |
| II. Separation of concerns | No code is added. The README's design reasoning describes the three layers `domain`, `application` and `infrastructure` (FR-010). | Pass |
| III. Short, readable methods | No method is added. CI runs RuboCop with `rubocop-rspec` on every push, so zero offences is checked on every commit (FR-020; DEC-36). The design reasoning goes in the README, not in code comments (FR-010; DEC-30, DEC-37). | Pass |
| IV. Tests first (NON-NEGOTIABLE) | This spec adds no behaviour, so it adds no RSpec spec (brief rule 4, FR-030). The rule still holds for its own work: each check in [quickstart.md](quickstart.md) is written and run before the file it checks, and fails until the file is right. CI runs the whole suite in random order (FR-020). | Pass (no behaviour to specify; checks first instead) |
| V. Check everything before any balance changes | Unaffected: no program behaviour changes. | Pass |
| VI. Money exact to the cent | Unaffected. The sample checks compare every closing balance byte for byte (C-10, C-13, C-19; DEC-35). | Pass |
| VII. No over-engineering | One CI job with no matrix and no threshold; a Dockerfile of six instructions with no extra packages and no `.dockerignore`; a one-line `.gitattributes`; checks kept as commands in `quickstart.md`, not as a new script folder (Decided in the run, items 3, 5 and 12). | Pass |
| VIII. Standard output for results only | Docker passes standard output, standard error and the exit status through unchanged (C-19, C-21). The README explains both streams and both exit statuses (FR-007, FR-008). | Pass |
| Technology constraints | No gem, framework or logging library is added. `actions/checkout` and `ruby/setup-ruby` are how a GitHub Actions workflow gets the code and Ruby; they are not dependencies of the program (Decided in the run, item 4). | Pass |
| Development workflow | Every check and task cites its FR or NFR and DEC IDs; every exact text the checks compare is copied from page 2 (AC-08.1, AC-08.4, AC-09.2, AC-09.3, AC-09.5). | Pass |

**Post-design re-check (after Phase 1)**: the contracts add nothing beyond the spec; no violation. Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-delivery/
├── spec.md              # The feature specification (/speckit-specify, /speckit-clarify)
├── plan.md              # This file (/speckit-plan)
├── research.md          # Phase 0: the choices behind each file, with alternatives
├── data-model.md        # Phase 1: the delivery files and checks as entities
├── quickstart.md        # Phase 1: the checks C-01 to C-41, with commands and expected outcomes
├── contracts/
│   ├── readme.md            # The README's sections, in order, and the README check R-01 to R-14
│   ├── ci-workflow.md       # What .github/workflows/ci.yml must hold, and must not
│   ├── dockerfile.md        # What the Dockerfile must hold, and the Docker commands
│   └── repository-files.md  # .gitattributes, Gemfile.lock platforms, bin/run, the submission listing
├── checklists/
│   └── requirements.md  # From /speckit-specify
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source code and files (repository root)

The folder layout is set by [page 5](../../docs/solution-design/05-high-level-design.md) and `001-domain` (FR-038 there: code under `lib/domain/`, `lib/application/` and `lib/infrastructure/`; specs mirroring it under `spec/`). This spec adds only the files marked **new** or **changed**; everything else is shown for the README's layout table.

```text
.github/
└── workflows/
    └── ci.yml           # new: one job, RSpec and RuboCop on every push (FR-020, FR-021)
.gitattributes           # new: exactly "bin/run text eol=lf" (FR-018)
Dockerfile               # new: the fallback way to run (FR-022 to FR-024)
README.md                # changed: rewritten to FR-001 to FR-014
Gemfile.lock             # changed: platforms added, gem versions unchanged (FR-017)
.ruby-version            # from 001: the Ruby version, read by CI and copied into the Dockerfile
Gemfile                  # from 001
.gitignore               # from 001: output/ and coverage/
.rspec                   # from 001
bin/run                  # from 002: stored executable, LF, "#!/usr/bin/env ruby" (FR-018)
lib/
├── domain/              # from 001
├── application/         # from 002
└── infrastructure/      # from 002
spec/                    # from 001 and 002, with spec/fixtures/sample/
data/                    # from 002: copies of the two challenge CSV files
docs/                    # challenge, design analysis, solution design, Spec Kit run, prompt logs
specs/                   # the Spec Kit specs, plans and tasks
.specify/, .claude/      # the Spec Kit set-up
```

**Structure Decision**: a single project, as `001-domain` and `002-file-runner` set it. This spec adds four files at fixed places (the README and the Dockerfile at the root, as DEC-36 and DEC-37 name them; `.gitattributes` at the root, where Git reads it; the workflow in `.github/workflows/`, where GitHub Actions reads it) and changes the platform list in `Gemfile.lock`. No folder is added except `.github/workflows/`, which GitHub requires.

## Phase 0: Research

See [research.md](research.md). There were no `NEEDS CLARIFICATION` items: the spec's clarifications and "Decided in the run" items fix every open point, and research records the choices for each file, with alternatives.

## Phase 1: Design

- [data-model.md](data-model.md): the delivery files, the coverage figure, the clean checkout and the submission, with the rules each must meet.
- [contracts/](contracts/): the README outline and check, the CI workflow, the Dockerfile and its commands, and the repository files.
- [quickstart.md](quickstart.md): every check, with its command and expected outcome, grouped by user story.

## Decided in the run

Small gaps decided while planning, consistent with `design-decisions.md` and the spec. Each is for the developer's review. The spec's own "Decided in the run" items 1 to 14 are not repeated.

| # | Decision | Relates to | Reason | Rejected |
|---|---|---|---|---|
| 1 | `.ruby-version` holds the bare version number (for example `3.4.7`, with no `ruby-` prefix), and the Dockerfile's first line is `FROM ruby:` followed by exactly that text. C-04 compares them. | FR-015, SC-005; DEC-01; 001 FR-036 | The same string is then the Docker tag and what `ruby/setup-ruby`, rbenv and RubyInstaller read, so one comparison proves the pin | Reading the version into the Dockerfile with a build argument (a second way to build); a `ruby-` prefix (not a Docker tag) |
| 2 | `Gemfile.lock` lists the platforms `ruby`, `x64-mingw-ucrt`, `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and `arm64-darwin`, added with `bundle lock --add-platform`; no gem version changes | FR-017, edge case "A lock file made on Windows"; DEC-01 | Windows (RubyInstaller), the Ubuntu runner and Docker on Intel hosts, Docker on Apple Silicon hosts, and macOS on both chips; `ruby` keeps a fallback for any other platform | Only the platform the lock file was made on (a frozen install elsewhere fails); only Windows and `x86_64-linux` (Docker on an ARM64 host fails) |
| 3 | The workflow is named `CI`, triggered by `on: push` with no branch filter, with one job `checks` on `ubuntu-latest` and five steps: check out the code (`actions/checkout@v5`), set up Ruby (`ruby/setup-ruby@v1` with no `ruby-version` input, so it reads `.ruby-version`), `bundle install` with `BUNDLE_FROZEN: "true"`, `bundle exec rspec`, `bundle exec rubocop` | FR-020, FR-021; DEC-36; page 10 pick 50 | Checking out the code is needed before anything runs, so it is part of installing, not an extra step; separate steps show which check failed; no input means one source for the version | A pull-request trigger as well; `bundler-cache: true` (installs into `vendor/bundle` in deployment mode, which RuboCop and SimpleCov would then have to exclude); a version written in the workflow |
| 4 | `actions/checkout` and `ruby/setup-ruby` are pinned to their major versions (`@v5`, `@v1`) | FR-020; constitution "Technology constraints" | The usual way to use these actions; they are how GitHub Actions gets the code and Ruby, not dependencies of the program | Commit SHAs (hard to read for a reviewer); no version (not allowed by GitHub) |
| 5 | The Dockerfile has six instructions in this order: `FROM ruby:<version>`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN bundle install`, `CMD ["bin/run"]` | FR-022 to FR-024; DEC-36; spec Clarifications | Exactly what DEC-36 lists, in that order; `/app` is the usual working folder in a container and becomes the project root; one `COPY` keeps the file to what DEC-36 says | Copying `Gemfile` and `Gemfile.lock` first for layer caching (one more instruction for a speed-up nobody asked for); a non-root user (spec Clarifications) |
| 6 | Frozen installs use the environment variable `BUNDLE_FROZEN=true` in CI, in the Dockerfile and in the clean-checkout checks; the README tells a reviewer to run plain `bundle install` | FR-017, US1 scenario 1; DEC-01 | A frozen install fails instead of changing `Gemfile.lock`, which is what the checks must prove; the `--frozen` flag is deprecated in Bundler 2; a reviewer only needs the normal command | `bundle install --frozen` (prints a deprecation warning); deployment mode (installs into `vendor/bundle`) |
| 7 | The Docker image must have time-zone data (`/usr/share/zoneinfo/Australia/Sydney` exists, C-18). If the default variant of `ruby:<version>` lacks it, the Dockerfile uses the `-bookworm` variant of the same version, which is still the full official image | FR-022, US3 scenario 2; DEC-36, DEC-37; spec item 5 | `TZ` only works with time-zone data, and FR-024 allows no extra system package; this keeps both rules without guessing | Installing `tzdata` (an extra package, against FR-024); a slim image (spec item 5) |
| 8 | The README's Docker commands are: build `docker build -t mable-transfers .`; run, POSIX shell, `docker run --rm -e TZ=Australia/Sydney -v "$(pwd)/output:/app/output" mable-transfers`; run, PowerShell, `docker run --rm -e TZ=Australia/Sydney -v "${PWD}/output:/app/output" mable-transfers`; tests `docker run --rm mable-transfers bundle exec rspec` | FR-005, US3; DEC-36, DEC-37 | `--rm` leaves no stopped container behind; `Australia/Sydney` is the spec's example and the README says to use the reviewer's own zone | No `--rm` (stopped containers pile up); `-it` (not needed, and fails when no terminal is attached) |
| 9 | The README's headings, in FR-001's order: `Build, test and run` (with `With Ruby 3.4`, `On Windows`, `With Docker`), `Input files`, `Log level and exit status`, `Assumptions`, `Design`, `Test coverage`, `Storage, production and known limitations`, `How this was built`, `Repository layout`, `The challenge` | FR-001 to FR-014; DEC-37; spec Clarifications | Plain names in the order the spec fixes; the README check (contracts/readme.md) finds each item by its heading | Other names; merging `LOG_LEVEL` and exit statuses into the run section (FR-001 gives them their own place) |
| 10 | The coverage figure is SimpleCov's printed line, `Line Coverage: <percent>% (<covered> / <total>)`, copied from a full `bundle exec rspec` run on a clean checkout of the final code; after the push, C-33 checks that the CI log for the latest `main` commit prints the same line | FR-012, SC-004; DEC-36 | The README holds no code, so changing it never changes the figure; the CI log is a record the reviewer can see | A rounded figure; a coverage badge (a service nobody asked for) |
| 11 | The README's title and the challenge link keep the challenge's own name; FR-014's "no company named" means the company whose balances are processed ([DEC-02](../../docs/design-analysis/design-decisions.md#dec-02)), which the README never names | FR-014; DEC-02 | DEC-02 is about the company in the files; the challenge's name is the repository's name and the link text to `docs/challenge/` | Removing the challenge's name from the title (the repository and challenge are named after it) |
| 12 | The checks are commands in [quickstart.md](quickstart.md), numbered C-01 to C-41; no script file or new folder is added for them; each result goes in the run report | FR-025, FR-030; constitution VII | Brief rule 4 checks this spec by hand and by CI; a script folder would be new code outside the decisions | A `script/` folder of check scripts; RSpec specs that read the README (brief rule 4) |
| 13 | "Every text file stored with LF" is checked in the index with `git ls-files --eol` (no `i/crlf` entry); byte-for-byte copies of the challenge files are checked by comparing Git blob IDs (`git rev-parse HEAD:<path>`). The same reason applies to C-03 (reads the lock file with `git show :Gemfile.lock`) and C-04 (strips CR from `.ruby-version` and the Dockerfile's first line), because a working copy with `core.autocrlf` holds CRLF | FR-018, FR-028; DEC-04, DEC-22 | Both read what Git stores, so the result is the same on Windows, where a checkout may convert line endings | Comparing working-copy files (differs on a Windows checkout with `core.autocrlf`) |
| 14 | If `bin/run` is not stored as executable (mode `100755`), the fix is `git update-index --chmod=+x bin/run`; the file's content does not change | FR-018; DEC-22 | A file committed from Windows loses its executable bit, and Git can set it without touching the content | Running `ruby bin/run` everywhere (spec item 7) |
| 15 | The Windows checks use a clean checkout made with `git clone -c core.autocrlf=true`, so the data files get CRLF line endings and US2 scenario 3 is proved by the run itself, and use PowerShell (`$LASTEXITCODE`) | FR-025(b), US2; DEC-04 | Forces the CRLF case on purpose instead of depending on the machine's Git setting | Relying on the machine's own `core.autocrlf` (the check might never see CRLF) |
| 16 | The Google Sheet link and the design-analysis "Status" text leave the README; the repository layout row for `docs/design-analysis/clarifications/` stays | FR-014; DEC-37 | FR-014 replaces the "Status" section; the copies of the sheet are in the repository | Keeping the "Status" section; dropping the clarifications row |
| 17 | In Git Bash on Windows, the Docker checks (C-17 to C-27) and the Phase 4 fallback container run with `export MSYS_NO_PATHCONV=1`; otherwise they run from a Linux or WSL shell | FR-025(a), FR-025(c); US3 | Git Bash rewrites arguments that start with `/` (`/usr/share/zoneinfo/...`, `-w /src`, the container side of `-v`) before `docker.exe` sees them, which would fail C-18 for the wrong reason and force a needless `-bookworm` change (item 7) | Doubling the leading slash (`//usr/...`, a different command from the README's); running the checks in PowerShell only (the commands are POSIX) |
| 18 | C-19 creates `output/` on the host (`mkdir -p output`) before the first mounted run | US3; C-23, C-24, C-27 | A mount folder the Docker daemon creates on Linux belongs to root, so the host user could not remove it or write in it | Running C-23 and C-24 with `sudo` |

## Complexity Tracking

No constitution violations; nothing to justify.
