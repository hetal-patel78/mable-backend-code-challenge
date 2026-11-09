# Research: Delivery: README, CI, Docker and the submission

[Phase 0](plan.md#phase-0-research) of the [plan](plan.md). The spec has no `NEEDS CLARIFICATION` item: its [Clarifications](spec.md#clarifications) (session 2026-11-07) and its "Decided in the run" [items 1](spec.md#item-1) to [18](spec.md#item-18) fix every open point. This page records the choice behind each file, with the alternatives, so the tasks can be followed without guessing. "Plan item n" refers to the plan's "Decided in the run" table.

<a id="r-1"></a>
## R-1 The Ruby version in one place, copied once

- **Decision**: [`.ruby-version`](../../.ruby-version) (from `001-domain`) holds the bare version number, for example `3.4.12`, as pinned by `001` plan [D1](../001-domain/plan.md#d1). The Dockerfile's first line is `FROM ruby:` followed by exactly that text. The CI workflow gives `ruby/setup-ruby` no version, so it reads [`.ruby-version`](../../.ruby-version). When the version changes, [`.ruby-version`](../../.ruby-version) and the Dockerfile change in the same commit ([FR-015](spec.md#fr-015); [plan item 1](plan.md#item-1)).
- **Rationale**: [DEC-01](../../docs/design-analysis/design-decisions.md#dec-01) pins the version "in [`.ruby-version`](../../.ruby-version) and in the Dockerfile"; Docker cannot read [`.ruby-version`](../../.ruby-version), so the Dockerfile is the one copy, and [C-04](quickstart.md#c-04) compares the two.
- **Alternatives considered**: a build argument read from [`.ruby-version`](../../.ruby-version) by a wrapper command (a second way to build the image); a version in the workflow ([page 10 pick 50](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50) rejects it).

<a id="r-2"></a>
## R-2 The lock file installs unchanged everywhere

- **Decision**: the platforms `ruby`, `x64-mingw-ucrt`, `x86_64-linux`, `aarch64-linux`, `x86_64-darwin` and `arm64-darwin` are added to [`Gemfile.lock`](../../Gemfile.lock) with `bundle lock --add-platform` ([plan item 2](plan.md#item-2)). Every check install is frozen with `BUNDLE_FROZEN=true` ([plan item 6](plan.md#item-6)), then `git status --porcelain Gemfile.lock` must print nothing.
- **Rationale**: a lock file made on Windows lists only the Windows platform, and Bundler with the frozen setting refuses to add the Linux platform on CI or in Docker (spec edge case; [FR-017](spec.md#fr-017)). The gems in the bundle are platform-independent (`ruby` platform), so adding platforms changes no version. Docker Desktop on Apple Silicon builds an `aarch64-linux` image, so that platform is needed too.
- **Alternatives considered**: not freezing (versions could drift; rejected by [spec item 4](spec.md#item-4)); deployment mode (installs into `vendor/bundle`; a plain frozen install already gives what [spec item 4](spec.md#item-4) asks, so the extra mode is not needed).

<a id="r-3"></a>
## R-3 `bin/run` starts on every system

- **Decision**: [`bin/run`](../../bin/run) (from `002-file-runner`) is stored as mode `100755`, starts with `#!/usr/bin/env ruby` and is stored with LF in the index; `002-file-runner` builds [`bin/run`](../../bin/run) with the `#!/usr/bin/env ruby` line, the `# frozen_string_literal: true` comment and mode `100755` (002 plan [P26](../002-file-runner/plan.md#p26); 002 tasks [T036](../002-file-runner/tasks.md#t036)); this spec checks them as [NFR-04](../../docs/solution-design/03-non-functional-requirements.md#nfr-04) targets ([C-01](quickstart.md#c-01), [C-43](quickstart.md#c-43)) and keeps a fix-only-if-missing step as a safeguard ([spec item 16](spec.md#item-16)). There is no `.gitattributes`: a Windows checkout made with `core.autocrlf=true` gives [`bin/run`](../../bin/run) CRLF like every other Ruby file ([FR-018](spec.md#fr-018); spec [Clarifications](spec.md#clarifications); [spec item 17](spec.md#item-17)). If the mode is wrong, `git update-index --chmod=+x bin/run` sets it; if the first line is missing, this spec adds it ([plan item 14](plan.md#item-14)).
- **Rationale**: Linux and macOS start [`bin/run`](../../bin/run) directly ([DEC-22](../../docs/design-analysis/design-decisions.md#dec-22)); their checkouts are LF. Giving [`bin/run`](../../bin/run) the shebang brings it under RuboCop. RuboCop's `Layout/EndOfLine`, with its default style `native`, wants CRLF on Windows and LF elsewhere, so it is turned off ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36); [`.rubocop.yml`](../../.rubocop.yml) belongs to `001`), and the line endings Git gives raise no offence. Forcing [`bin/run`](../../bin/run) to LF with `.gitattributes` is not needed, and [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36) rejects it. A CRLF first line makes the kernel look for `ruby\r`, which fails with "No such file or directory", so the Docker image runs `ruby bin/run`, which starts it whatever the line ending; Ruby on Linux then writes `bin/run:1: warning: shebang line ending with \r may cause problems` on standard error, so the image strips the carriage returns from [`bin/run`](../../bin/run) ([R-6](#r-6); [spec item 18](spec.md#item-18)). Research note, checked against the published gem source: `rubocop-rspec`'s own `config/default.yml` sets `Metrics/BlockLength` with `inherit_mode` merge for `Exclude` and `Exclude: ["**/*_spec.rb", "**/spec/**/*"]`, so with `plugins: [rubocop-rspec]` and default settings the spec files are not checked by it; zero offences is reachable under [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36).
- **Alternatives considered**: `bin/run text eol=lf` or `* text=auto eol=lf` in `.gitattributes` (rejected by [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36): every existing Windows checkout would need checking out again); a `# rubocop:disable Layout/EndOfLine` comment (the cop is turned off for every file in [`.rubocop.yml`](../../.rubocop.yml), [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)); `CMD ["bin/run"]` (fails from a Windows checkout with a CRLF shebang line).

<a id="r-4"></a>
## R-4 Every text file stored with LF

- **Decision**: checked in the index with `git ls-files --eol`: no line may show `i/crlf` ([plan item 13](plan.md#item-13)). Windows checkouts may still give working files CRLF; the CSV library reads them the same ([DEC-04](../../docs/design-analysis/design-decisions.md#dec-04)).
- **Rationale**: what Git stores is what every clone starts from; the working copy differs by machine.
- **Alternatives considered**: checking working files (differs on Windows).

<a id="r-5"></a>
## R-5 The CI workflow

- **Decision**: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml), named `CI`, `on: push` with no branch filter, one job `checks` on `ubuntu-latest`, steps: `actions/checkout@v5`; `ruby/setup-ruby@v1` with no inputs; `bundle install` with `BUNDLE_FROZEN: "true"`; `bundle exec rspec`; `bundle exec rubocop` ([plan items 3](plan.md#item-3) and [4](plan.md#item-4)). See [contracts/ci-workflow.md](contracts/ci-workflow.md).
- **Rationale**: [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36) says RSpec and RuboCop run on every push; [page 10 pick 50](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50) sets one job on the latest Ubuntu runner with Ruby from [`.ruby-version`](../../.ruby-version). Each command is its own step, and a step fails the job when its command exits non-zero, so a failing check fails the run without any extra setting ([US4](spec.md#us4) scenario 2). With no `ruby-version` input, `ruby/setup-ruby` reads [`.ruby-version`](../../.ruby-version).
- **Alternatives considered**: `bundler-cache: true` (installs in deployment mode into `vendor/bundle` and adds caching nobody asked for; [plan item 6](plan.md#item-6) already gives a plain frozen install); a pull-request trigger (not asked); an OS or Ruby-version matrix ([page 9](../../docs/solution-design/09-considerations.md) "Portability and CI", [page 10 pick 50](../../docs/solution-design/10-traceability-glossary-assumptions.md#pick-50)); a coverage minimum ([page 4](../../docs/solution-design/04-scope.md), out of scope).

<a id="r-6"></a>
## R-6 The Dockerfile

- **Decision**: six instructions: `FROM ruby:<version>`, `WORKDIR /app`, `COPY . .`, `ENV BUNDLE_FROZEN=true`, `RUN sed -i 's/\r$//' bin/run && bundle install`, `CMD ["ruby", "bin/run"]` ([plan item 5](plan.md#item-5); [spec item 18](spec.md#item-18)). See [contracts/dockerfile.md](contracts/dockerfile.md).
- **Rationale**: [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36): "the official Ruby image matching [`.ruby-version`](../../.ruby-version), copies the project in, runs `bundle install`, and by default runs [`bin/run`](../../bin/run) on the sample files". The exec form makes `ruby` (running [`bin/run`](../../bin/run)) the container's main process, so the exit status of `docker run` is the program's, and a command after the image name replaces it (spec [Clarifications](spec.md#clarifications)). Running the file through `ruby` instead of its shebang means an image built from a Windows checkout, where [`bin/run`](../../bin/run) may have CRLF line endings, still starts it. Ruby on Linux warns on standard error about a `#!` line ending in a carriage return (`bin/run:1: warning: shebang line ending with \r may cause problems`, seen in the run by [C-41](quickstart.md#c-41)), and the specs that start [`bin/run`](../../bin/run) as its own process fail on that line, so the `RUN` instruction first strips the carriage returns from [`bin/run`](../../bin/run) with `sed`, which the official image has; on a LF checkout it changes nothing. `/app` as the working folder is the project root, so the report shows `Output file: output/...` and the log shows `data/...` ([FR-023](spec.md#fr-023)). The official image runs as root and sets `BUNDLE_SILENCE_ROOT_WARNING`, so Bundler prints no root warning on standard error.
- **Alternatives considered**: a slim image ([spec item 5](spec.md#item-5)); `bundle exec bin/run` (spec [Clarifications](spec.md#clarifications)); a `.dockerignore` ([spec item 13](spec.md#item-13)); copying the gem files first for caching ([plan item 5](plan.md#item-5)); `CMD ["ruby", "-W0", "bin/run"]` or `ENV RUBYOPT=-W0` instead of stripping the carriage returns ([spec item 18](spec.md#item-18)).

<a id="r-7"></a>
## R-7 Time-zone data in the image

- **Decision**: [C-18](quickstart.md#c-18) checks that `/usr/share/zoneinfo/Australia/Sydney` exists in the built image. If the default variant of `ruby:<version>` lacks it, the Dockerfile uses the `-bookworm` variant of the same version ([plan item 7](plan.md#item-7)).
- **Rationale**: the container's file name uses local time from `TZ` ([DEC-27](../../docs/design-analysis/design-decisions.md#dec-27), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)), which needs the zone files. [FR-024](spec.md#fr-024) allows no extra system package, so the fix, if needed, is the choice of variant, not `apt-get install tzdata`.
- **Alternatives considered**: installing `tzdata` (an extra package); accepting UTC (breaks [US3](spec.md#us3) scenario 2).

<a id="r-8"></a>
## R-8 The README

- **Decision**: the sections and order in [contracts/readme.md](contracts/readme.md), headings as in [plan item 9](plan.md#item-9); the sample report copied from [AC-08.1](../../docs/solution-design/02-functional-requirements.md#ac-08-1) with [page 2](../../docs/solution-design/02-functional-requirements.md)'s run time ([spec item 8](spec.md#item-8)); the usage message copied from [AC-09.2](../../docs/solution-design/02-functional-requirements.md#ac-09-2); the assumptions copied from [`design-decisions.md`](../../docs/design-analysis/design-decisions.md) with their reasons ([spec item 10](spec.md#item-10)); the known limitations one line each from [page 9](../../docs/solution-design/09-considerations.md)'s risks table and [page 10](../../docs/solution-design/10-traceability-glossary-assumptions.md) ([spec item 11](spec.md#item-11)); "How this was built" with the four steps and their links ([spec item 12](spec.md#item-12)).
- **Rationale**: [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37) lists what the README gives; the spec's clarification fixes the order; copying exact text keeps one version of each.
- **Alternatives considered**: describing the design in code comments (rejected by [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)); a shorter README that links to the solution design for everything (a reviewer would have to leave the README for the commands).

<a id="r-9"></a>
## R-9 The coverage figure

- **Decision**: SimpleCov's printed line, `Line coverage: <covered> / <total> (<percent>%)`, from a full `bundle exec rspec` on a clean checkout of the final code, with a sentence that the full report is in `coverage/index.html` and that there is no minimum ([FR-012](spec.md#fr-012); [plan item 10](plan.md#item-10)).
- **Rationale**: [DEC-36](../../docs/design-analysis/design-decisions.md#dec-36): the README shows the figure; no threshold. The README is not code, so writing it does not change the figure; [C-33](quickstart.md#c-33) compares it with the CI log of the latest `main` commit.
- **Alternatives considered**: a badge from a coverage service (a new service); rounding.

<a id="r-10"></a>
## R-10 The clean checkout and the hand checks

- **Decision**: a clean checkout is `git clone` of `origin` at `main` into a new, empty folder outside the repository ([spec item 2](spec.md#item-2)). The Windows clone uses `-c core.autocrlf=true` ([plan item 15](plan.md#item-15)). A check that cannot run on the machine at hand is listed in the run report as left for the developer, never as passed ([FR-025](spec.md#fr-025)).
- **Rationale**: proves the pushed files alone are enough; forces the CRLF case on Windows.
- **Alternatives considered**: a worktree (shares the repository); the working copy after `git clean` ([spec item 2](spec.md#item-2)).

<a id="r-11"></a>
## R-11 The submission check

- **Decision**: `git ls-files` on `main` for the list in [US6](spec.md#us6) scenario 1; no path under `output/` or `coverage/`; `git status --porcelain` empty after a run and a test run; [`docs/challenge/`](../../docs/challenge/) compared with the commit that added it (`git diff --exit-code <that commit> HEAD -- docs/challenge/`); the copies in [`data/`](../../data/) and [`spec/fixtures/sample/`](../../spec/fixtures/sample/) compared by blob ID ([plan item 13](plan.md#item-13)); the CI status of the latest `main` commit read with `gh run list --branch main --limit 1` or on the Actions page. Making the repository public or sharing it is left to the developer ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)).
- **Rationale**: each command reads what the reviewer will see.
- **Alternatives considered**: checking the working copy (may hold ignored or generated files).

## Risks found while planning

| Risk | Effect | Handling |
|---|---|---|
| The default `ruby:<version>` variant has no time-zone data | `TZ` is ignored and the file name uses UTC | [C-18](quickstart.md#c-18), then the `-bookworm` variant ([R-7](#r-7)) |
| [`bin/run`](../../bin/run) committed from Windows without the executable bit | [`bin/run`](../../bin/run) fails with "permission denied" on Linux, macOS and CI | [C-01](quickstart.md#c-01), then `git update-index --chmod=+x` ([R-3](#r-3)) |
| The lock file lacks a platform | A frozen install fails on CI, in Docker or on a reviewer's machine | [C-03](quickstart.md#c-03), then `bundle lock --add-platform` ([R-2](#r-2)) |
| No Ruby 3.4 for Windows, or no Docker, on the machine running the checks | A hand check cannot run | Listed in the run report as left for the developer ([FR-025](spec.md#fr-025)) |
