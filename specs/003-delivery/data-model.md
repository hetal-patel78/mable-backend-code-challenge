# Data model: Delivery: README, CI, Docker and the submission

Phase 1 of the [plan](plan.md). This spec adds no class and no runtime data (FR-030). Its "entities" are the delivery files and the checks around them, named as in the spec's Key Entities and the [page 10 glossary](../../docs/solution-design/10-traceability-glossary-assumptions.md#glossary). Each lists its fields (what it holds), the rules it must meet, and the checks in [quickstart.md](quickstart.md) that prove them.

## README (`README.md`)

- **Holds**: the sections in [contracts/readme.md](contracts/readme.md), in that order (FR-001).
- **Rules**:
  - Every item R-01 to R-14 in the README check is present (FR-001 to FR-014; SC-003).
  - Every exact text is copied from page 2: the sample report (AC-08.1, with the run time `2026-11-07_143005`), the usage message (AC-09.2) (FR-002, FR-003; US5 scenario 3).
  - Every command works as written on a clean checkout (US5 scenario 2); every relative link opens a file or folder in the repository (US5 scenario 5).
  - Names no company whose balances are processed ([DEC-02](../../docs/design-analysis/design-decisions.md#dec-02)) (FR-014; plan item 11).
  - The design reasoning is here, not in code comments ([DEC-30](../../docs/design-analysis/design-decisions.md#dec-30), [DEC-37](../../docs/design-analysis/design-decisions.md#dec-37)).
- **Checks**: C-29 to C-33.

## Coverage figure

- **Holds**: SimpleCov's line `Line Coverage: <percent>% (<covered> / <total>)` (FR-012).
- **Rules**: taken from a full `bundle exec rspec` run on the final code; equals what a fresh run prints on the submitted commit (SC-004); no minimum is stated or enforced ([DEC-36](../../docs/design-analysis/design-decisions.md#dec-36)).
- **Changes when**: any file under `lib/` or `spec/` changes. A README-only commit does not change it.
- **Checks**: C-33.

## CI workflow (`.github/workflows/ci.yml`)

- **Holds**: the name `CI`, the trigger, one job and five steps, as in [contracts/ci-workflow.md](contracts/ci-workflow.md) (FR-020).
- **Rules**: runs on every push to any branch; Ruby from `.ruby-version`; frozen install; RSpec and RuboCop as separate steps; no matrix, no coverage minimum, no Ruby version, no other step (FR-021); no step ignores errors (US4 scenario 2).
- **States of a run**: queued → in progress → success (every step exits with 0) or failure (a step exits non-zero; later steps do not run).
- **Checks**: C-06, C-07, C-38.

## Dockerfile and the image `mable-transfers`

- **Holds**: six instructions, as in [contracts/dockerfile.md](contracts/dockerfile.md) (FR-022).
- **Rules**: base image `ruby:<the text of .ruby-version>`, the full image (or its `-bookworm` variant, plan item 7); working folder `/app`, the project root (FR-023); frozen `bundle install`; default command `CMD ["bin/run"]` in exec form; nothing else: no extra package, no other gem, no `.dockerignore` (FR-024); runs as the image's default user, root (spec Clarifications).
- **Checks**: C-04, C-17 to C-26.

## `.gitattributes`

- **Holds**: exactly one line, `bin/run text eol=lf`, ending with LF (FR-018; spec Clarifications).
- **Checks**: C-02, C-26.

## `Gemfile.lock` (changed here; built by `001-domain`)

- **Holds**: the gem versions `001-domain` locked, unchanged, and the `PLATFORMS` list `aarch64-linux`, `arm64-darwin`, `ruby`, `x64-mingw-ucrt`, `x86_64-darwin`, `x86_64-linux` (Bundler sorts them) (FR-017; plan item 2).
- **Rules**: a frozen `bundle install` succeeds and leaves it unchanged on Windows, the CI runner and in the image (SC-005).
- **Checks**: C-03, C-09, C-13, C-17, C-07.

## `bin/run` (checked here; built by `002-file-runner`)

- **Holds**: Git mode `100755`; first line `#!/usr/bin/env ruby`; LF line endings in the index and in every checkout (FR-018).
- **Checks**: C-01, C-26.

## Clean checkout

- **Holds**: a fresh `git clone` of `main` into a new, empty folder outside the repository, with no `output/`, `coverage/` or installed gems carried over (spec Conventions, item 2); on Windows, cloned with `core.autocrlf=true` (plan item 15).
- **Used by**: C-08 to C-26, C-36.

## Run report entry

- **Holds**, for each check: its ID, the platform, the date, the commit, passed or failed, and the evidence (the command's output or a summary of it). A check that cannot run on the machine at hand is "left for the developer", never "passed" (FR-025).
- **Lives in**: `docs/spec-kit/implementation-run-report.md`, Part 2 section.

## Submission

- **Holds**: the link to the GitHub repository `origin` (`hetal-patel78/mable-backend-code-challenge`), branch `main` ([DEC-38](../../docs/design-analysis/design-decisions.md#dec-38)).
- **Rules**: the files in US6 scenario 1 are tracked; nothing under `output/` or `coverage/`; `docs/challenge/` unchanged; the copies in `data/` and `spec/fixtures/sample/` identical to it; the latest commit's CI run is a success; making the repository public or sharing it is left to the developer (FR-026 to FR-029).
- **Checks**: C-35 to C-39.
